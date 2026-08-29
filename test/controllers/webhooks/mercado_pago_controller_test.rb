require "test_helper"
require "openssl"

# Each branch asserts both the public HTTP contract and its persisted audit result.
# rubocop:disable-next Metrics/ClassLength
class Webhooks::MercadoPagoControllerTest < ActionDispatch::IntegrationTest
  WEBHOOK_SECRET = "test-webhook-secret"

  ServiceDouble = Struct.new(:call_result, :result, :payment, :remote_status, :error, keyword_init: true) do
    def call
      raise error if error

      call_result
    end
  end

  setup do
    @previous_webhook_secret = ENV["MERCADO_PAGO_WEBHOOK_SECRET"]
    ENV["MERCADO_PAGO_WEBHOOK_SECRET"] = WEBHOOK_SECRET
  end

  teardown do
    ENV["MERCADO_PAGO_WEBHOOK_SECRET"] = @previous_webhook_secret
  end

  test "accepts and audits a signed payment notification" do
    service = service_double(call_result: true, result: :approved, remote_status: "approved")

    SyncMercadoPagoPaymentService.stub(:new, ->(**) { service }) do
      post_webhook(data_id: "mp-webhook-payment")
    end

    assert_response :ok
    assert_delivery(
      status: "processed",
      service_result: "approved",
      remote_status: "approved",
      response_status: 200,
      resource_id: "mp-webhook-payment",
      event_type: "payment"
    )
  end

  test "does not persist a notification with an invalid signature" do
    headers = signed_headers("mp-invalid-signature").merge(
      "X-Signature" => "ts=#{Time.current.to_i},v1=invalid"
    )

    assert_no_difference("WebhookDelivery.count") do
      post_webhook(data_id: "mp-invalid-signature", headers: headers)
    end

    assert_response :unauthorized
  end

  test "does not persist a notification with an expired signature" do
    timestamp = 10.minutes.ago.to_i.to_s

    assert_no_difference("WebhookDelivery.count") do
      post_webhook(
        data_id: "mp-expired-signature",
        headers: signed_headers("mp-expired-signature", timestamp: timestamp)
      )
    end

    assert_response :unauthorized
  end

  test "does not persist a request when the webhook secret is missing" do
    ENV["MERCADO_PAGO_WEBHOOK_SECRET"] = ""

    assert_no_difference("WebhookDelivery.count") do
      post_webhook(data_id: "mp-missing-secret")
    end

    assert_response :service_unavailable
  end

  test "acknowledges and audits signed events that are not payments" do
    SyncMercadoPagoPaymentService.stub(:new, ->(**) { flunk "payment service should not be called" }) do
      post_webhook(data_id: "merchant-order-event", type: "merchant_order")
    end

    assert_response :ok
    assert_delivery(status: "ignored", event_type: "merchant_order", response_status: 200)
  end

  test "rejects and audits a signed payment event without data id" do
    SyncMercadoPagoPaymentService.stub(:new, ->(**) { flunk "payment service should not be called" }) do
      post_webhook(data_id: "")
    end

    assert_response :bad_request
    assert_delivery(status: "invalid", failure_code: "missing_payment_id", response_status: 400)
  end

  test "records an unknown local payment" do
    service = service_double(call_result: false, result: :not_found)

    SyncMercadoPagoPaymentService.stub(:new, ->(**) { service }) do
      post_webhook(data_id: "mp-missing-payment")
    end

    assert_response :not_found
    assert_delivery(
      status: "not_found",
      service_result: "not_found",
      failure_code: "local_payment_not_found",
      response_status: 404
    )
  end

  test "audits an unprocessable service result" do
    service = service_double(call_result: false, result: :unsupported)

    SyncMercadoPagoPaymentService.stub(:new, ->(**) { service }) do
      post_webhook(data_id: "mp-unprocessable")
    end

    assert_response :unprocessable_content
    assert_delivery(
      status: "invalid",
      service_result: "unsupported",
      failure_code: "unprocessable_result",
      response_status: 422
    )
  end

  test "audits a processing exception without changing its retry response" do
    error = MercadoPagoPaymentGateway::InvalidResponseError.new("sensitive gateway payload")
    service = service_double(error: error)

    SyncMercadoPagoPaymentService.stub(:new, ->(**) { service }) do
      post_webhook(data_id: "mp-gateway-error")
    end

    assert_response :bad_gateway
    assert_delivery(
      status: "failed",
      failure_code: "gateway_invalid_response",
      error_class: "MercadoPagoPaymentGateway::InvalidResponseError",
      response_status: 502
    )
  end

  test "keeps the webhook available when audit persistence fails" do
    WebhookDelivery.stub(:create!, ->(*) { raise ActiveRecord::ConnectionNotEstablished, "audit unavailable" }) do
      post_webhook(data_id: "merchant-order-event", type: "merchant_order")
    end

    assert_response :ok
  end

  test "stores each authenticated replay as a separate delivery" do
    assert_difference("WebhookDelivery.count", 2) do
      2.times { post_webhook(data_id: "merchant-order-replay", type: "merchant_order") }
    end
  end

  private

  def service_double(**attributes)
    ServiceDouble.new(
      call_result: nil,
      result: nil,
      payment: nil,
      remote_status: nil,
      error: nil,
      **attributes
    )
  end

  def post_webhook(data_id:, type: "payment", headers: signed_headers(data_id))
    post webhook_url(data_id),
      params: { type: type, data: { id: data_id } },
      headers: headers,
      as: :json
  end

  def webhook_url(data_id)
    webhooks_mercado_pago_url("data.id" => data_id)
  end

  # rubocop:disable-next Metrics/MethodLength
  def signed_headers(data_id, timestamp: Time.current.to_i.to_s)
    request_id = SecureRandom.uuid
    manifest_parts = []
    normalized_id = data_id.to_s.strip.downcase
    manifest_parts << "id:#{normalized_id}" unless normalized_id.empty?
    manifest_parts << "request-id:#{request_id}"
    manifest_parts << "ts:#{timestamp}"
    signature = OpenSSL::HMAC.hexdigest("SHA256", WEBHOOK_SECRET, "#{manifest_parts.join(';')};")

    {
      "X-Request-Id" => request_id,
      "X-Signature" => "ts=#{timestamp},v1=#{signature}"
    }
  end

  def assert_delivery(**attributes)
    delivery = WebhookDelivery.order(:created_at).last

    attributes.each { |attribute, value| assert_equal value, delivery.public_send(attribute) }
  end
end
