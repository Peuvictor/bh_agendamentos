require "mercadopago/webhook/validator"

module Webhooks
  class MercadoPagoController < ApplicationController
    SIGNATURE_TOLERANCE = 5.minutes.to_i

    skip_forgery_protection
    before_action :initialize_delivery
    before_action :verify_signature!

    def create
      return respond_with_delivery(:ignored, :ok) unless event_type == "payment"

      payment_id = resource_id
      return respond_with_delivery(:invalid, :bad_request, failure_code: "missing_payment_id") if payment_id.blank?

      service = SyncMercadoPagoPaymentService.new(payment_id: payment_id)

      if service.call
        respond_with_delivery(
          :processed,
          :ok,
          service: service
        )
      elsif service.result == :not_found
        respond_with_delivery(
          :not_found,
          :not_found,
          service: service,
          failure_code: "local_payment_not_found"
        )
      else
        respond_with_delivery(
          :invalid,
          :unprocessable_content,
          service: service,
          failure_code: "unprocessable_result"
        )
      end
    rescue StandardError => error
      respond_with_delivery(
        :failed,
        :bad_gateway,
        service: service,
        error: error
      )
    end

    private

    def initialize_delivery
      @delivery_recorder = WebhookDeliveryRecorder.new(request: request, event_type: event_type)
    end

    def verify_signature!
      secret = ENV["MERCADO_PAGO_WEBHOOK_SECRET"].to_s

      if secret.blank?
        record_delivery(
          status: :failed,
          response_status: :service_unavailable,
          failure_code: "configuration_error"
        )
        return head :service_unavailable
      end

      Mercadopago::Webhook::Validator.validate(
        request.headers["x-signature"],
        request.headers["x-request-id"],
        request.query_parameters["data.id"],
        secret,
        tolerance_seconds: SIGNATURE_TOLERANCE
      )
      @delivery_recorder.authenticated!
    rescue Mercadopago::Webhook::InvalidWebhookSignatureError => error
      record_delivery(
        status: :invalid,
        response_status: :unauthorized,
        failure_code: "invalid_signature",
        error: error,
        signature_reason: error.reason
      )
      head :unauthorized
    end

    def respond_with_delivery(status, response_status, service: nil, failure_code: nil, error: nil)
      record_delivery(
        status: status,
        response_status: response_status,
        service: service,
        failure_code: failure_code,
        error: error
      )
      head response_status
    end

    def record_delivery(**attributes)
      @delivery_recorder.record(**attributes)
    end

    def event_type
      params[:type].to_s
    end

    def resource_id
      @delivery_recorder.resource_id
    end
  end
end
