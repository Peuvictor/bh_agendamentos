require "test_helper"
require "openssl"

class Webhooks::MercadoPagoControllerTest < ActionDispatch::IntegrationTest
  WEBHOOK_SECRET = "test-webhook-secret"

  setup do
    @previous_webhook_secret = ENV["MERCADO_PAGO_WEBHOOK_SECRET"]
    ENV["MERCADO_PAGO_WEBHOOK_SECRET"] = WEBHOOK_SECRET
  end

  teardown do
    ENV["MERCADO_PAGO_WEBHOOK_SECRET"] = @previous_webhook_secret
  end

  test "accepts a signed payment notification without user authentication" do
    payment_id = "mp-webhook-payment"
    service = Minitest::Mock.new
    service.expect :call, true

    factory = lambda do |payment_id:|
      assert_equal "mp-webhook-payment", payment_id
      service
    end

    SyncMercadoPagoPaymentService.stub(:new, factory) do
      post webhook_url(payment_id),
        params: { type: "payment", data: { id: payment_id } },
        headers: signed_headers(payment_id),
        as: :json
    end

    assert_response :ok
    service.verify
  end

  test "rejects a notification with an invalid signature" do
    payment_id = "mp-invalid-signature"
    headers = signed_headers(payment_id).merge("X-Signature" => "ts=#{Time.current.to_i},v1=invalid")

    post webhook_url(payment_id),
      params: { type: "payment", data: { id: payment_id } },
      headers: headers,
      as: :json

    assert_response :unauthorized
  end

  test "acknowledges signed events that are not payments" do
    event_id = "merchant-order-event"

    SyncMercadoPagoPaymentService.stub(:new, ->(**) { flunk "payment service should not be called" }) do
      post webhook_url(event_id),
        params: { type: "merchant_order", data: { id: event_id } },
        headers: signed_headers(event_id),
        as: :json
    end

    assert_response :ok
  end

  private

  def webhook_url(data_id)
    webhooks_mercado_pago_url("data.id" => data_id)
  end

  def signed_headers(data_id)
    timestamp = Time.current.to_i.to_s
    request_id = SecureRandom.uuid
    manifest = "id:#{data_id.downcase};request-id:#{request_id};ts:#{timestamp};"
    signature = OpenSSL::HMAC.hexdigest("SHA256", WEBHOOK_SECRET, manifest)

    {
      "X-Request-Id" => request_id,
      "X-Signature" => "ts=#{timestamp},v1=#{signature}"
    }
  end
end
