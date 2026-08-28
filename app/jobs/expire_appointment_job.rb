# frozen_string_literal: true

require 'English'

class ExpireAppointmentJob < ApplicationJob
  queue_as :maintenance

  def perform(appointment_id)
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    service = ExpireAppointmentService.new(appointment_id: appointment_id)
    service.call
  ensure
    log_result(appointment_id, service, started_at, $ERROR_INFO)
  end

  private

  def log_result(appointment_id, service, started_at, error)
    duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
    attributes = {
      appointment_id: appointment_id,
      payment_id: service&.payment_id,
      result: error ? :error : service&.result,
      remote_status: service&.remote_status,
      duration_ms: duration_ms,
      error_class: error&.class&.name
    }.compact

    Rails.logger.info("appointment_expiration #{attributes.map { |key, value| "#{key}=#{value}" }.join(' ')}")
  end
end
