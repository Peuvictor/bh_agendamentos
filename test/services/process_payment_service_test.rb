require "test_helper"
require "mercadopago"

class ProcessPaymentServiceTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  include ActiveJob::TestHelper

  test "confirms the appointment and sends email after an approved payment" do
    appointment = build_appointment
    service = payment_service_for(appointment)

    assert_enqueued_emails 1 do
      with_gateway_response(status: "approved", id: "mp-approved") do
        assert service.call
      end
    end

    assert appointment.reload.confirmado?
    assert appointment.payment.aprovado?
  end

  test "keeps the appointment pending and does not send email for a pending payment" do
    appointment = build_appointment
    service = payment_service_for(appointment)

    assert_no_enqueued_emails do
      with_gateway_response(status: "pending", id: "mp-pending") do
        assert service.call
      end
    end

    assert appointment.reload.pendente?
    assert appointment.payment.pendente?
  end

  private

  def build_appointment
    Appointment.create!(
      client: users(:two),
      service: services(:one),
      start_time: 6.days.from_now.change(hour: 15, min: 0)
    )
  end

  def payment_service_for(appointment)
    ProcessPaymentService.new(
      appointment: appointment,
      token: "test-token",
      payment_method_id: "pix",
      issuer_id: nil,
      installments: 1
    )
  end

  def with_gateway_response(status:, id:)
    payment_api = Minitest::Mock.new
    payment_api.expect(
      :create,
      { response: { "status" => status, "id" => id } },
      [Hash],
      request_options: Mercadopago::RequestOptions
    )

    sdk = Object.new
    sdk.define_singleton_method(:payment) { payment_api }

    Mercadopago::SDK.stub(:new, sdk) { yield }
    payment_api.verify
  end
end
