require "test_helper"
require "mercadopago"

# rubocop:disable-next Metrics/ClassLength
class SyncMercadoPagoPaymentServiceTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  include ActiveJob::TestHelper

  test "approves a pending PIX and confirms its appointment" do
    payment = create_pending_payment("mp-pix-approved")
    service = SyncMercadoPagoPaymentService.new(payment_id: payment.mp_transaction_id)

    assert_enqueued_emails 1 do
      with_gateway_payment(payment, status: "approved") do
        assert service.call
      end
    end

    assert_equal :approved, service.result
    assert payment.reload.aprovado?
    assert payment.appointment.reload.confirmado?
  end

  test "processes repeated approval notifications only once" do
    payment = create_pending_payment("mp-pix-repeated")
    first_service = SyncMercadoPagoPaymentService.new(payment_id: payment.mp_transaction_id)

    assert_enqueued_emails 1 do
      with_gateway_payment(payment, status: "approved") { assert first_service.call }
    end

    repeated_service = SyncMercadoPagoPaymentService.new(payment_id: payment.mp_transaction_id)

    assert_no_enqueued_emails do
      with_gateway_payment(payment, status: "approved") { assert repeated_service.call }
    end

    assert_equal :already_processed, repeated_service.result
  end

  test "keeps local records pending while the gateway payment is pending" do
    payment = create_pending_payment("mp-pix-pending")
    service = SyncMercadoPagoPaymentService.new(payment_id: payment.mp_transaction_id)

    assert_no_enqueued_emails do
      with_gateway_payment(payment, status: "pending") { assert service.call }
    end

    assert_equal :pending, service.result
    assert payment.reload.pendente?
    assert payment.appointment.reload.pendente?
  end

  test "does not reopen a canceled appointment when its PIX is approved" do
    payment = create_pending_payment("mp-pix-canceled-appointment")
    payment.appointment.update!(status: :cancelado)
    service = SyncMercadoPagoPaymentService.new(payment_id: payment.mp_transaction_id)

    assert_no_enqueued_emails do
      with_gateway_payment(payment, status: "approved") { assert service.call }
    end

    assert_equal :approved_without_confirmation, service.result
    assert payment.reload.aprovado?
    assert payment.appointment.reload.cancelado?
  end

  test "rejects gateway data with a different amount" do
    payment = create_pending_payment("mp-wrong-amount")
    service = SyncMercadoPagoPaymentService.new(payment_id: payment.mp_transaction_id)

    error = assert_raises(SyncMercadoPagoPaymentService::InvalidGatewayPaymentError) do
      with_gateway_payment(payment, status: "approved", amount: payment.amount + 1) { service.call }
    end

    assert_includes error.message, "amount"
    assert payment.reload.pendente?
    assert payment.appointment.reload.pendente?
  end

  test "reconciles a total refund and notifies the client once" do
    payment = create_pending_payment("mp-refunded")
    payment.update!(status: :aprovado)
    payment.appointment.update!(status: :confirmado)
    service = SyncMercadoPagoPaymentService.new(payment_id: payment.mp_transaction_id)

    assert_enqueued_emails 1 do
      with_gateway_payment(payment, status: "refunded") { assert service.call }
    end

    assert_equal :refunded, service.result
    assert_predicate payment.reload, :reembolsado?
    assert_predicate payment.refunded_at, :present?
    assert_predicate payment.appointment.reload, :reembolsado?
    assert_predicate payment.appointment.refunded_at, :present?
  end

  test "does not duplicate a refund or let a delayed approval reverse it" do
    payment = create_pending_payment("mp-refunded-repeated")
    first_service = SyncMercadoPagoPaymentService.new(payment_id: payment.mp_transaction_id)

    assert_enqueued_emails 1 do
      with_gateway_payment(payment, status: "refunded") { assert first_service.call }
    end
    refunded_at = payment.reload.refunded_at

    repeated_service = SyncMercadoPagoPaymentService.new(payment_id: payment.mp_transaction_id)
    assert_no_enqueued_emails do
      with_gateway_payment(payment, status: "refunded") { assert repeated_service.call }
    end

    delayed_service = SyncMercadoPagoPaymentService.new(payment_id: payment.mp_transaction_id)
    assert_no_enqueued_emails do
      with_gateway_payment(payment, status: "approved") { assert delayed_service.call }
    end

    assert_equal :already_refunded, repeated_service.result
    assert_equal :already_refunded, delayed_service.result
    assert_predicate payment.reload, :reembolsado?
    assert_equal refunded_at, payment.refunded_at
    assert_predicate payment.appointment.reload, :reembolsado?
  end

  test "refund prevails over a local cancellation" do
    payment = create_pending_payment("mp-refunded-cancelled")
    payment.update!(status: :cancelado)
    payment.appointment.update!(status: :cancelado)
    service = SyncMercadoPagoPaymentService.new(payment_id: payment.mp_transaction_id)

    assert_enqueued_emails 1 do
      with_gateway_payment(payment, status: "refunded") { assert service.call }
    end

    assert_equal :refunded, service.result
    assert_predicate payment.reload, :reembolsado?
    assert_predicate payment.appointment.reload, :reembolsado?
  end

  test "keeps the approved behavior for a partial refund detail" do
    payment = create_pending_payment("mp-partially-refunded")
    service = SyncMercadoPagoPaymentService.new(payment_id: payment.mp_transaction_id)

    assert_enqueued_emails 1 do
      with_gateway_payment(payment, status: "approved", status_detail: "partially_refunded") do
        assert service.call
      end
    end

    assert_equal :approved, service.result
    assert_predicate payment.reload, :aprovado?
    assert_predicate payment.appointment.reload, :confirmado?
    assert_nil payment.refunded_at
  end

  private

  def create_pending_payment(transaction_id)
    appointment = Appointment.create!(
      client: users(:two),
      service: services(:one),
      start_time: 8.days.from_now.change(hour: 15, min: 0)
    )

    Payment.create!(
      appointment: appointment,
      amount: appointment.service.preco,
      status: :pendente,
      mp_transaction_id: transaction_id,
      idempotency_key: "idempotency-#{transaction_id}"
    )
  end

  def with_gateway_payment(payment, status:, amount: payment.amount, status_detail: nil)
    response = {
      status: 200,
      response: {
        "id" => payment.mp_transaction_id,
        "status" => status,
        "status_detail" => status_detail,
        "transaction_amount" => amount.to_s,
        "external_reference" => payment.appointment_id
      }
    }

    payment_api = Minitest::Mock.new
    payment_api.expect :get, response, [payment.mp_transaction_id]

    sdk = Object.new
    sdk.define_singleton_method(:payment) { payment_api }

    Mercadopago::SDK.stub(:new, sdk) { yield }
    payment_api.verify
  end
end
