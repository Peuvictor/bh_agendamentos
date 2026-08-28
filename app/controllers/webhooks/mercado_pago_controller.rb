require "mercadopago/webhook/validator"

module Webhooks
  class MercadoPagoController < ApplicationController
    SIGNATURE_TOLERANCE = 5.minutes.to_i

    skip_forgery_protection
    before_action :verify_signature!

    def create
      return head :ok unless params[:type] == "payment"

      payment_id = request.query_parameters["data.id"].to_s
      return head :bad_request if payment_id.blank?

      service = SyncMercadoPagoPaymentService.new(payment_id: payment_id)

      if service.call
        head :ok
      elsif service.result == :not_found
        head :not_found
      else
        head :unprocessable_content
      end
    rescue StandardError => error
      Rails.logger.error(
        "Mercado Pago webhook processing failed " \
        "request_id=#{request.headers['x-request-id']} error=#{error.class}: #{error.message}"
      )
      head :bad_gateway
    end

    private

    def verify_signature!
      secret = ENV["MERCADO_PAGO_WEBHOOK_SECRET"].to_s

      if secret.blank?
        Rails.logger.error("MERCADO_PAGO_WEBHOOK_SECRET is not configured")
        return head :service_unavailable
      end

      Mercadopago::Webhook::Validator.validate(
        request.headers["x-signature"],
        request.headers["x-request-id"],
        request.query_parameters["data.id"],
        secret,
        tolerance_seconds: SIGNATURE_TOLERANCE
      )
    rescue Mercadopago::Webhook::InvalidWebhookSignatureError => error
      Rails.logger.warn(
        "Invalid Mercado Pago webhook signature " \
        "request_id=#{error.request_id} reason=#{error.reason}"
      )
      head :unauthorized
    end
  end
end
