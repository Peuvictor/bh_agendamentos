# frozen_string_literal: true

require 'json'

class WebhookEventLogger
  def initialize(context, logger: nil)
    @context = context
    @logger = logger
  end

  def terminal(attributes, signature_reason: nil)
    payload = context_payload.merge(result_payload(attributes, signature_reason)).compact
    logger.public_send(log_level(attributes), JSON.generate(payload))
  rescue StandardError
    nil
  end

  def write_failure(error)
    payload = context_payload.slice(:event, :mp_request_id, :rails_request_id).merge(
      event: 'webhook_observability_write_failed',
      error_class: error.class.name
    )
    logger.error(JSON.generate(payload.compact))
  rescue StandardError
    nil
  end

  private

  attr_reader :context

  def logger
    @logger || Rails.logger
  end

  def context_payload
    {
      event: 'mercado_pago_webhook',
      notification_type: context[:event_type],
      resource_id: context[:resource_id],
      mp_request_id: context[:gateway_request_id],
      rails_request_id: context[:rails_request_id]
    }
  end

  def result_payload(attributes, signature_reason)
    {
      outcome: outcome(attributes),
      http_status: attributes[:response_status],
      local_payment_id: attributes[:payment]&.id
    }.merge(diagnostic_payload(attributes, signature_reason))
  end

  def diagnostic_payload(attributes, signature_reason)
    {
      sync_result: attributes[:service_result],
      remote_status: attributes[:remote_status],
      failure_code: attributes[:failure_code],
      signature_reason: signature_reason,
      error_class: attributes[:error_class],
      duration_ms: attributes[:duration_ms]
    }
  end

  def outcome(attributes)
    status = attributes[:status].to_sym
    return status.to_s if %i[processed ignored not_found].include?(status)
    return attributes[:failure_code] || 'invalid' if status == :invalid
    return 'configuration_error' if attributes[:failure_code] == 'configuration_error'

    'processing_error'
  end

  def log_level(attributes)
    return :info if %i[processed ignored].include?(attributes[:status].to_sym)
    return :error if attributes[:response_status] >= 500

    :warn
  end
end
