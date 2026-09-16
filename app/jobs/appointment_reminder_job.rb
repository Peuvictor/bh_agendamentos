# frozen_string_literal: true

class AppointmentReminderJob < ApplicationJob
  queue_as :default

  def perform(appointment_id)
    appointment = Appointment.find_by(id: appointment_id)
    return unless appointment

    appointment.with_lock do
      next unless appointment.reminder_due?

      AppointmentMailer.reminder_email(appointment).deliver_now
      appointment.update!(reminder_sent_at: Time.current)
    end
  end
end
