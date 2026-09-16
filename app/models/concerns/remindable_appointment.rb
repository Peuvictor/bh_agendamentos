# frozen_string_literal: true

module RemindableAppointment
  extend ActiveSupport::Concern

  LEAD_TIME = 24.hours

  included do
    before_update :reset_reminder_tracking, if: :will_save_change_to_start_time?
  end

  def reminder_due?(at: Time.current)
    confirmado? && start_time.present? && start_time > at && start_time <= at + LEAD_TIME && reminder_sent_at.nil?
  end

  private

  def reset_reminder_tracking
    self.reminder_enqueued_at = nil
    self.reminder_sent_at = nil
  end
end
