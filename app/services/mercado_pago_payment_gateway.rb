# frozen_string_literal: true

require 'mercadopago'

class MercadoPagoPaymentGateway
  class InvalidResponseError < StandardError; end

  def initialize(sdk: nil)
    @sdk = sdk || Mercadopago::SDK.new(ENV.fetch('MERCADO_PAGO_ACCESS_TOKEN', nil))
  end

  def create_payment(payment_data, idempotency_key:)
    request_options = Mercadopago::RequestOptions.new(
      custom_headers: { 'x-idempotency-key' => idempotency_key }
    )
    result = @sdk.payment.create(payment_data, request_options: request_options)

    response_body!(result, operation: 'create')
  end

  def fetch_payment(payment_id)
    response_body!(@sdk.payment.get(payment_id.to_s), operation: 'fetch')
  end

  def cancel_payment(payment_id)
    result = @sdk.payment.update(payment_id.to_s, { status: 'cancelled' })

    response_body!(result, operation: 'cancel')
  end

  private

  def response_body!(result, operation:)
    status = result[:status] || result['status']
    body = result[:response] || result['response']

    unless (status.nil? || status.to_i.between?(200, 299)) && body.is_a?(Hash)
      raise InvalidResponseError, "Mercado Pago #{operation} returned HTTP #{status || 'unknown'}"
    end

    body
  end
end
