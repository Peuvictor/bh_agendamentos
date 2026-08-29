# frozen_string_literal: true

require 'test_helper'
require 'json'

# Recorder safety is intentionally verified across persistence and logging in each scenario.
# rubocop:disable-next Minitest/MultipleAssertions
class WebhookDeliveryRecorderTest < ActiveSupport::TestCase
  RequestDouble = Data.define(:headers, :request_id, :query_parameters, :request_parameters)

  class CapturingLogger
    attr_reader :entries

    def initialize
      @entries = []
    end

    %i[info warn error].each do |level|
      define_method(level) { |message| entries << [level, message] }
    end
  end

  test 'persists authenticated metadata and emits one structured terminal event' do
    logger = CapturingLogger.new
    recorder = build_recorder

    Rails.stub(:logger, logger) do
      recorder.authenticated!
      recorder.record(status: :processed, response_status: :ok)
    end

    delivery = WebhookDelivery.order(:created_at).last
    terminal_events = parsed_events(logger, 'mercado_pago_webhook')

    assert_predicate delivery, :status_processed?
    assert_equal 200, delivery.response_status
    assert_predicate delivery.completed_at, :present?
    assert_equal 1, terminal_events.size
    assert_equal 'processed', terminal_events.first.fetch('outcome')
  end

  test 'logs an unauthenticated rejection without persisting it' do
    logger = CapturingLogger.new
    recorder = build_recorder

    assert_no_difference('WebhookDelivery.count') do
      Rails.stub(:logger, logger) do
        recorder.record(
          status: :invalid,
          response_status: :unauthorized,
          failure_code: 'invalid_signature',
          signature_reason: :signature_mismatch
        )
      end
    end

    event = parsed_events(logger, 'mercado_pago_webhook').sole

    assert_equal 'invalid_signature', event.fetch('outcome')
    assert_equal 'signature_mismatch', event.fetch('signature_reason')
  end

  test 'does not leak exception messages and survives an audit write failure' do
    logger = CapturingLogger.new
    recorder = build_recorder(request_id: "request\nid")
    failure = ->(*) { raise StandardError, 'secret token and payer payload' }

    Rails.stub(:logger, logger) do
      WebhookDelivery.stub(:create!, failure) do
        recorder.authenticated!
        recorder.record(status: :ignored, response_status: :ok)
      end
    end

    output = logger.entries.map(&:last).join("\n")
    terminal_event = parsed_events(logger, 'mercado_pago_webhook').sole

    assert_no_match(/secret token|payer payload/, output)
    assert_equal 'requestid', terminal_event.fetch('mp_request_id')
    assert_equal 'ignored', terminal_event.fetch('outcome')
    assert_predicate parsed_events(logger, 'webhook_observability_write_failed'), :one?
  end

  test 'classifies known processing errors and normalizes unknown remote states' do
    logger = CapturingLogger.new
    recorder = build_recorder
    service = Struct.new(:payment, :result, :remote_status).new(nil, nil, 'charged_back')

    Rails.stub(:logger, logger) do
      recorder.authenticated!
      recorder.record(
        status: :failed,
        response_status: :bad_gateway,
        service: service,
        error: Timeout::Error.new('gateway details')
      )
    end

    delivery = WebhookDelivery.order(:created_at).last
    event = parsed_events(logger, 'mercado_pago_webhook').sole

    assert_equal 'gateway_timeout', delivery.failure_code
    assert_equal 'unknown', delivery.remote_status
    assert_equal 'processing_error', event.fetch('outcome')
    assert_equal 'Timeout::Error', event.fetch('error_class')
  end

  private

  def build_recorder(request_id: 'mp-request-id')
    request = RequestDouble.new(
      headers: { 'x-request-id' => request_id },
      request_id: 'rails-request-id',
      query_parameters: { 'data.id' => 'mp-payment-id' },
      request_parameters: { 'action' => 'payment.updated' }
    )
    WebhookDeliveryRecorder.new(request: request, event_type: 'payment')
  end

  def parsed_events(logger, event_name)
    logger.entries.filter_map do |_level, message|
      event = JSON.parse(message)
      event if event['event'] == event_name
    end
  end
end
