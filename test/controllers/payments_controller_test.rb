require "test_helper"

class PaymentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client = users(:two)
    @appointment = Appointment.create!(
      client: @client,
      service: services(:one),
      start_time: 7.days.from_now.change(hour: 16, min: 0)
    )
    sign_in @client
  end

  test "returns the real gateway status" do
    payment_service = Minitest::Mock.new
    payment_service.expect :call, true
    payment_service.expect :payload, { "status" => "pending", "id" => "mp-pending" }

    ProcessPaymentService.stub(:new, ->(**) { payment_service }) do
      post payments_url, params: payment_params
    end

    response_body = JSON.parse(response.body)

    assert_response :created
    assert_equal "pending", response_body["status"]
    payment_service.verify
  end

  test "does not allow payment for another clients appointment" do
    sign_out @client
    sign_in users(:one)

    post payments_url, params: payment_params

    assert_response :not_found
  end

  test "does not allow payment for a canceled appointment" do
    @appointment.update!(status: :cancelado)

    post payments_url, params: payment_params

    assert_response :unprocessable_content
    assert_equal "rejected", JSON.parse(response.body)["status"]
  end

  test "does not start another charge when a payment already exists" do
    Payment.create!(
      appointment: @appointment,
      amount: @appointment.service.preco,
      status: :pendente,
      mp_transaction_id: "mp-existing",
      idempotency_key: "existing-idempotency-key"
    )

    post payments_url, params: payment_params

    assert_response :unprocessable_content
    assert_includes JSON.parse(response.body)["error"], "em processamento"
  end

  private

  def payment_params
    {
      appointment_id: @appointment.id,
      payment: {
        token: "test-token",
        installments: 1,
        payment_method_id: "pix"
      }
    }
  end
end
