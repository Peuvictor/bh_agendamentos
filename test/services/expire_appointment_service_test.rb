# frozen_string_literal: true

require 'test_helper'

# The state matrix intentionally keeps each remote outcome and its persisted invariants together.
# rubocop:disable-next Metrics/ClassLength, Minitest/MultipleAssertions
class ExpireAppointmentServiceTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  class FakeGateway
    attr_reader :cancel_calls, :fetch_calls

    def initialize(fetch_responses:, cancel_response: nil, cancel_error: nil)
      @fetch_responses = fetch_responses.is_a?(Array) ? fetch_responses.dup : [fetch_responses]
      @cancel_response = cancel_response
      @cancel_error = cancel_error
      @cancel_calls = 0
      @fetch_calls = 0
    end

    def fetch_payment(_payment_id)
      @fetch_calls += 1
      response = @fetch_responses.shift || @fetch_responses.last
      raise response if response.is_a?(Exception)

      response
    end

    def cancel_payment(_payment_id)
      @cancel_calls += 1
      raise @cancel_error if @cancel_error

      @cancel_response
    end
  end

  test 'expires an overdue appointment without payment and releases its slot once' do
    appointment = create_expired_appointment
    service = ExpireAppointmentService.new(appointment_id: appointment.id, gateway: unused_gateway)

    assert_enqueued_emails 1 do
      assert service.call
    end

    assert_equal :expired_without_payment, service.result
    assert_predicate appointment.reload, :cancelado?
    assert_predicate appointment.expired_at, :present?

    replacement = Appointment.new(
      client: users(:one),
      service: appointment.service,
      start_time: appointment.start_time
    )

    assert_predicate replacement, :valid?

    assert_no_enqueued_emails { service.call }
    assert_equal :not_due, service.result
  end

  test 'ignores an appointment whose expiration is still in the future' do
    appointment = create_expired_appointment
    appointment.update!(expires_at: 5.minutes.from_now)
    service = ExpireAppointmentService.new(appointment_id: appointment.id, gateway: unused_gateway)

    assert_no_enqueued_emails { assert service.call }

    assert_equal :not_due, service.result
    assert_predicate appointment.reload, :pendente?
  end

  test 'preserves and confirms an overdue appointment when Mercado Pago is approved' do
    payment = create_expired_payment
    gateway = FakeGateway.new(fetch_responses: gateway_payment(payment, 'approved'))
    service = ExpireAppointmentService.new(appointment_id: payment.appointment_id, gateway: gateway)

    assert_enqueued_emails 1 do
      assert service.call
    end

    assert_equal :approved, service.result
    assert_predicate payment.reload, :aprovado?
    assert_predicate payment.appointment.reload, :confirmado?
    assert_nil payment.expires_at
    assert_nil payment.appointment.expires_at
    assert_equal 0, gateway.cancel_calls
  end

  %w[pending in_process authorized].each do |remote_status|
    test "cancels and expires a #{remote_status} Mercado Pago payment" do
      payment = create_expired_payment(transaction_id: "mp-#{remote_status}")
      gateway = FakeGateway.new(
        fetch_responses: gateway_payment(payment, remote_status),
        cancel_response: gateway_payment(payment, 'cancelled')
      )
      service = ExpireAppointmentService.new(appointment_id: payment.appointment_id, gateway: gateway)

      assert_enqueued_emails 1 do
        assert service.call
      end

      assert_equal :cancelled, service.result
      assert_predicate payment.reload, :cancelado?
      assert_predicate payment.expired_at, :present?
      assert_predicate payment.appointment.reload, :cancelado?
      assert_predicate payment.appointment.expired_at, :present?
      assert_equal 1, gateway.cancel_calls
    end
  end

  test 'expires locally when Mercado Pago already reports cancelled' do
    payment = create_expired_payment(transaction_id: 'mp-already-cancelled')
    gateway = FakeGateway.new(fetch_responses: gateway_payment(payment, 'cancelled'))
    service = ExpireAppointmentService.new(appointment_id: payment.appointment_id, gateway: gateway)

    assert_enqueued_emails 1 do
      assert service.call
    end

    assert_equal :cancelled, service.result
    assert_predicate payment.reload, :cancelado?
    assert_predicate payment.appointment.reload, :cancelado?
    assert_equal 0, gateway.cancel_calls
  end

  test 'marks a rejected payment and expires its appointment' do
    payment = create_expired_payment(transaction_id: 'mp-rejected')
    gateway = FakeGateway.new(fetch_responses: gateway_payment(payment, 'rejected'))
    service = ExpireAppointmentService.new(appointment_id: payment.appointment_id, gateway: gateway)

    assert_enqueued_emails 1 do
      assert service.call
    end

    assert_equal :rejected, service.result
    assert_predicate payment.reload, :rejeitado?
    assert_predicate payment.expired_at, :present?
    assert_predicate payment.appointment.reload, :cancelado?
  end

  test 'rechecks after a cancellation conflict and preserves an approved appointment' do
    payment = create_expired_payment(transaction_id: 'mp-raced-approval')
    gateway = FakeGateway.new(
      fetch_responses: [gateway_payment(payment, 'pending'), gateway_payment(payment, 'approved')],
      cancel_error: MercadoPagoPaymentGateway::InvalidResponseError.new(
        operation: 'cancel',
        status: 400,
        response: { 'error' => 'bad_request' }
      )
    )
    service = ExpireAppointmentService.new(appointment_id: payment.appointment_id, gateway: gateway)

    assert_enqueued_emails 1 do
      assert service.call
    end

    assert_equal :approved, service.result
    assert_predicate payment.reload, :aprovado?
    assert_predicate payment.appointment.reload, :confirmado?
    assert_equal 2, gateway.fetch_calls
  end

  test 'keeps the slot reserved when cancellation fails and payment remains pending' do
    payment = create_expired_payment(transaction_id: 'mp-cancel-timeout')
    timeout = Timeout::Error.new('gateway timeout')
    gateway = FakeGateway.new(
      fetch_responses: [gateway_payment(payment, 'pending'), gateway_payment(payment, 'pending')],
      cancel_error: timeout
    )
    service = ExpireAppointmentService.new(appointment_id: payment.appointment_id, gateway: gateway)

    assert_no_enqueued_emails do
      assert_raises(Timeout::Error) { service.call }
    end

    assert_predicate payment.reload, :pendente?
    assert_predicate payment.appointment.reload, :pendente?
    assert_nil payment.expired_at
    assert_nil payment.appointment.expired_at
  end

  test 'keeps the slot reserved after a temporary fetch failure' do
    payment = create_expired_payment(transaction_id: 'mp-fetch-timeout')
    gateway = FakeGateway.new(fetch_responses: Timeout::Error.new('gateway timeout'))
    service = ExpireAppointmentService.new(appointment_id: payment.appointment_id, gateway: gateway)

    assert_raises(Timeout::Error) { service.call }

    assert_predicate payment.reload, :pendente?
    assert_predicate payment.appointment.reload, :pendente?
  end

  test 'reconciles a refunded payment and releases the expired slot' do
    payment = create_expired_payment(transaction_id: 'mp-refunded')
    gateway = FakeGateway.new(fetch_responses: gateway_payment(payment, 'refunded'))
    service = ExpireAppointmentService.new(appointment_id: payment.appointment_id, gateway: gateway)

    assert_enqueued_emails 1 do
      assert service.call
    end

    assert_equal :refunded, service.result
    assert_predicate payment.reload, :reembolsado?
    assert_predicate payment.appointment.reload, :reembolsado?
    assert_equal 0, gateway.cancel_calls
  end

  test 'reconciles a refund after a cancellation conflict' do
    payment = create_expired_payment(transaction_id: 'mp-raced-refund')
    gateway = FakeGateway.new(
      fetch_responses: [gateway_payment(payment, 'pending'), gateway_payment(payment, 'refunded')],
      cancel_error: MercadoPagoPaymentGateway::InvalidResponseError.new(
        operation: 'cancel',
        status: 400,
        response: { 'error' => 'bad_request' }
      )
    )
    service = ExpireAppointmentService.new(appointment_id: payment.appointment_id, gateway: gateway)

    assert_enqueued_emails 1 do
      assert service.call
    end

    assert_equal :refunded, service.result
    assert_predicate payment.reload, :reembolsado?
    assert_predicate payment.appointment.reload, :reembolsado?
    assert_equal 2, gateway.fetch_calls
  end

  test 'keeps the slot reserved for an unknown remote state' do
    payment = create_expired_payment(transaction_id: 'mp-unknown')
    gateway = FakeGateway.new(fetch_responses: gateway_payment(payment, 'charged_back'))
    service = ExpireAppointmentService.new(appointment_id: payment.appointment_id, gateway: gateway)

    assert_raises(PaymentStateTransitionService::UnknownRemoteStatusError) { service.call }

    assert_predicate payment.reload, :pendente?
    assert_predicate payment.appointment.reload, :pendente?
  end

  test 'keeps the slot reserved when amount or external reference diverges' do
    payment = create_expired_payment(transaction_id: 'mp-divergent')

    [
      gateway_payment(payment, 'cancelled', amount: payment.amount + 1),
      gateway_payment(payment, 'cancelled', external_reference: SecureRandom.uuid)
    ].each do |response|
      service = ExpireAppointmentService.new(
        appointment_id: payment.appointment_id,
        gateway: FakeGateway.new(fetch_responses: response)
      )

      assert_raises(MercadoPagoPaymentValidator::InvalidPaymentError) { service.call }
      assert_predicate payment.reload, :pendente?
      assert_predicate payment.appointment.reload, :pendente?
    end
  end

  private

  def create_expired_appointment
    Appointment.create!(
      client: users(:two),
      service: services(:one),
      start_time: 10.days.from_now.change(hour: 10, min: 0),
      expires_at: 1.minute.ago
    )
  end

  def create_expired_payment(transaction_id: 'mp-expired')
    appointment = create_expired_appointment
    Payment.create!(
      appointment: appointment,
      amount: appointment.service.preco,
      status: :pendente,
      mp_transaction_id: transaction_id,
      idempotency_key: "idempotency-#{transaction_id}",
      expires_at: appointment.expires_at
    )
  end

  def gateway_payment(payment, status, amount: payment.amount, external_reference: payment.appointment_id)
    {
      'id' => payment.mp_transaction_id,
      'status' => status,
      'transaction_amount' => amount.to_s,
      'external_reference' => external_reference.to_s
    }
  end

  def unused_gateway
    Object.new.tap do |gateway|
      gateway.define_singleton_method(:fetch_payment) { flunk 'gateway should not be called' }
    end
  end
end
