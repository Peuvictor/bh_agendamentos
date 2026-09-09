# frozen_string_literal: true

module ReschedulableAppointment
  def reschedulable?
    confirmado? && payment&.aprovado? && start_time.present? && start_time > Time.current &&
      !service.archived? && reserved_duration.present?
  end

  def reserved_duration
    return unless start_time && end_time && end_time > start_time

    (end_time - start_time) / 60
  end

  def schedule_token
    schedule_verifier.generate(schedule_identity)
  end

  def current_schedule_token?(token)
    schedule_verifier.verified(token, purpose: nil) == schedule_identity
  end

  private

  def schedule_verifier
    Rails.application.message_verifier('appointment-rescheduling')
  end

  def schedule_identity
    [id, start_time&.iso8601(6), end_time&.iso8601(6), updated_at&.iso8601(6)]
  end
end
