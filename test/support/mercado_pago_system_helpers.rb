# frozen_string_literal: true

require 'openssl'

module MercadoPagoSystemHelpers
  class FakeGateway
    attr_reader :created_payment_data

    def initialize(create_response: nil, fetch_responses: [], cancel_response: nil)
      @create_response = create_response
      @fetch_responses = Array(fetch_responses)
      @cancel_response = cancel_response
    end

    def create_payment(payment_data, idempotency_key:)
      @created_payment_data = payment_data.merge(idempotency_key: idempotency_key)
      @create_response
    end

    def fetch_payment(_payment_id)
      @fetch_responses.shift || raise('No fake fetch response configured')
    end

    def cancel_payment(_payment_id)
      @cancel_response || raise('No fake cancellation response configured')
    end
  end

  def submit_browser_payment(gateway:, method:, form_data:)
    MercadoPagoPaymentGateway.stub(:new, gateway) do
      page.execute_script(<<~JS, method, form_data)
        const controller = window.Stimulus.getControllerForElementAndIdentifier(
          document.querySelector('[data-controller="payment"]'),
          'payment'
        );
        controller.clearInitializationTimeout();
        controller.submitPayment(arguments[0], arguments[1]).catch(() => {});
      JS
      yield
    end
  end

  # rubocop:disable-next Metrics/MethodLength
  def post_signed_payment_webhook(payment:, gateway:)
    headers = signed_webhook_headers(payment.mp_transaction_id)
    path = webhooks_mercado_pago_path('data.id' => payment.mp_transaction_id)

    MercadoPagoPaymentGateway.stub(:new, gateway) do
      result = page.evaluate_async_script(<<~JS, path, headers, payment.mp_transaction_id)
        const done = arguments[3];
        fetch(arguments[0], {
          method: 'POST',
          headers: { ...arguments[1], 'Content-Type': 'application/json' },
          body: JSON.stringify({ type: 'payment', data: { id: arguments[2] } })
        })
          .then(response => done({ status: response.status }))
          .catch(error => done({ error: error.message }));
      JS

      assert_equal 200, result.fetch('status'), result['error']
    end
  end

  def gateway_payment(payment, status)
    {
      'id' => payment.mp_transaction_id,
      'status' => status,
      'transaction_amount' => payment.amount.to_s,
      'external_reference' => payment.appointment_id.to_s
    }
  end

  private

  def signed_webhook_headers(payment_id)
    timestamp = Time.current.to_i.to_s
    request_id = SecureRandom.uuid
    manifest = "id:#{payment_id.to_s.downcase};request-id:#{request_id};ts:#{timestamp};"
    signature = OpenSSL::HMAC.hexdigest('SHA256', ENV.fetch('MERCADO_PAGO_WEBHOOK_SECRET'), manifest)

    {
      'X-Request-Id' => request_id,
      'X-Signature' => "ts=#{timestamp},v1=#{signature}"
    }
  end
end
