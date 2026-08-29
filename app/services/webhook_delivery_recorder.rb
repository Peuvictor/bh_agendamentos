# frozen_string_literal: true

class WebhookDeliveryRecorder
  REMOTE_STATUSES = %w[approved authorized cancelled in_process pending refunded rejected].freeze
  ERROR_CODES = {
    'MercadoPagoPaymentGateway::InvalidResponseError' => 'gateway_invalid_response',
    'MercadoPagoPaymentValidator::InvalidPaymentError' => 'payment_validation_failed',
    'PaymentStateTransitionService::StateConflictError' => 'state_conflict',
    'PaymentStateTransitionService::UnknownRemoteStatusError' => 'unknown_remote_status',
    'Timeout::Error' => 'gateway_timeout'
  }.freeze

  def initialize(request:, event_type:)
    @request = request
    @started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    @base_attributes = request_attributes(event_type)
    @event_logger = WebhookEventLogger.new(@base_attributes)
  end

  def resource_id
    @resource_id ||= @request.query_parameters['data.id'].to_s
  end

  def authenticated!
    @delivery = WebhookDelivery.create!(@base_attributes.merge(status: :received))
  rescue StandardError => e
    @event_logger.write_failure(e)
    @delivery = nil
  end

  def record(status:, response_status:, **details)
    return if @recorded

    @recorded = true
    attributes = terminal_attributes(status, response_status, details)
    persist_terminal(attributes)
    @event_logger.terminal(attributes, signature_reason: bounded_value(details[:signature_reason], 100))
  rescue StandardError => e
    @event_logger.write_failure(e)
  ensure
    @delivery = nil
  end

  private

  def request_attributes(event_type)
    {
      gateway_request_id: bounded_value(@request.headers['x-request-id'], 255),
      rails_request_id: bounded_value(@request.request_id, 255),
      event_type: bounded_value(event_type, 100),
      event_action: bounded_value(event_action, 100),
      resource_id: bounded_value(resource_id, 255)
    }
  end

  def terminal_attributes(status, response_status, details)
    outcome_attributes(status, response_status)
      .merge(service_attributes(details[:service]))
      .merge(failure_attributes(details[:failure_code], details[:error]))
      .merge(duration_ms: elapsed_ms, completed_at: Time.current)
  end

  def outcome_attributes(status, response_status)
    { status: status, response_status: Rack::Utils.status_code(response_status) }
  end

  def service_attributes(service)
    {
      payment: service_value(service, :payment),
      service_result: bounded_value(service_value(service, :result), 100),
      remote_status: normalized_remote_status(service_value(service, :remote_status))
    }
  end

  def failure_attributes(failure_code, error)
    {
      failure_code: bounded_value(failure_code || error_code(error), 100),
      error_class: bounded_value(error&.class&.name, 255)
    }
  end

  def persist_terminal(attributes)
    @delivery&.update!(attributes)
  rescue StandardError => e
    @event_logger.write_failure(e)
  end

  def normalized_remote_status(value)
    status = bounded_value(value, 100)
    return if status.nil?

    REMOTE_STATUSES.include?(status) ? status : 'unknown'
  end

  def error_code(error)
    return if error.nil?

    ERROR_CODES.fetch(error.class.name, 'unexpected_error')
  end

  def service_value(service, method_name)
    return unless service
    return unless service.respond_to?(method_name)

    service.public_send(method_name)
  end

  def event_action
    @request.query_parameters['action'] || @request.request_parameters['action']
  end

  def bounded_value(value, limit)
    return if value.nil?

    value.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
         .gsub(/[[:cntrl:]]/, '').first(limit).presence
  end

  def elapsed_ms
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - @started_at) * 1000).round
  end
end
