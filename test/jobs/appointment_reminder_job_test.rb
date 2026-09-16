# frozen_string_literal: true

require 'test_helper'

# Delivery state, retry idempotency and cancellation are one reminder lifecycle.
class AppointmentReminderJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  test 'delivers a due reminder once when the job is repeated' do
    travel_to Time.zone.local(2026, 9, 16, 10) do
      appointment = create_appointment(start_time: 23.hours.from_now, status: :confirmado)

      assert_emails 1 do
        2.times { AppointmentReminderJob.perform_now(appointment.id) }
      end

      assert_predicate appointment.reload.reminder_sent_at, :present?
    end
  end

  test 'does not remind an appointment canceled after it was enqueued' do
    travel_to Time.zone.local(2026, 9, 16, 10) do
      appointment = create_appointment(start_time: 23.hours.from_now, status: :confirmado)
      appointment.update!(status: :cancelado)

      assert_no_emails { AppointmentReminderJob.perform_now(appointment.id) }
      assert_nil appointment.reload.reminder_sent_at
    end
  end

  test 'does not remind an appointment before it enters the 24 hour window' do
    travel_to Time.zone.local(2026, 9, 16, 10) do
      appointment = create_appointment(start_time: 25.hours.from_now, status: :confirmado)

      assert_no_emails { AppointmentReminderJob.perform_now(appointment.id) }
      assert_nil appointment.reload.reminder_sent_at
    end
  end

  private

  def create_appointment(start_time:, status:)
    Appointment.create!(
      client: users(:two),
      service: services(:one),
      start_time: start_time,
      status: status,
      reminder_enqueued_at: Time.current
    )
  end
end
