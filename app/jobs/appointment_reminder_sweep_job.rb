# frozen_string_literal: true

class AppointmentReminderSweepJob < ApplicationJob
  queue_as :maintenance

  BATCH_SIZE = 100
  CLAIM_TTL = 15.minutes

  def perform
    now = Time.current
    reminder_candidates(now).find_each(batch_size: BATCH_SIZE) do |appointment|
      enqueue_if_due(appointment, now)
    end
  end

  private

  def reminder_candidates(now)
    Appointment.confirmado
               .where(start_time: (now..(now + 24.hours)))
               .where(reminder_sent_at: nil)
               .where('reminder_enqueued_at IS NULL OR reminder_enqueued_at <= ?', now - CLAIM_TTL)
  end

  def enqueue_if_due(appointment, now)
    claimed = appointment.with_lock do
      next false unless appointment.reminder_due?(at: now)
      next false if appointment.reminder_enqueued_at.present? && appointment.reminder_enqueued_at > now - CLAIM_TTL

      appointment.update!(reminder_enqueued_at: now)
    end

    AppointmentReminderJob.perform_later(appointment.id) if claimed
  end
end
