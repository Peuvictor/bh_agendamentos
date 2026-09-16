# frozen_string_literal: true

require 'test_helper'

# Candidate selection and stale-claim recovery form one scheduling behavior.
# rubocop:disable-next Minitest/MultipleAssertions
class AppointmentReminderSweepJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  test 'enqueues confirmed appointments inside the next 24 hours only once' do
    travel_to Time.zone.local(2026, 9, 16, 10) do
      due = create_appointment(start_time: 1.hour.from_now, status: :confirmado)
      stale_claim = create_appointment(start_time: 2.hours.from_now, status: :confirmado,
                                       reminder_enqueued_at: 16.minutes.ago)
      create_appointment(start_time: 3.hours.from_now, status: :confirmado, reminder_enqueued_at: 5.minutes.ago)
      create_appointment(start_time: 4.hours.from_now, status: :confirmado, reminder_sent_at: 1.hour.ago)
      create_appointment(start_time: 5.hours.from_now, status: :pendente)
      create_appointment(start_time: 25.hours.from_now, status: :confirmado)

      assert_enqueued_jobs 2, only: AppointmentReminderJob do
        AppointmentReminderSweepJob.perform_now
      end

      enqueued_ids = enqueued_jobs.filter_map do |job|
        job[:args].first if job[:job] == AppointmentReminderJob
      end

      assert_equal [due.id, stale_claim.id].sort, enqueued_ids.sort
      assert_predicate due.reload.reminder_enqueued_at, :present?
      assert_predicate stale_claim.reload.reminder_enqueued_at, :present?
      assert_equal 'maintenance', AppointmentReminderSweepJob.queue_name
      assert_equal 'default', AppointmentReminderJob.queue_name
    end
  end

  private

  def create_appointment(start_time:, status:, reminder_enqueued_at: nil, reminder_sent_at: nil)
    Appointment.create!(
      client: users(:two),
      service: services(:one),
      start_time: start_time,
      status: status,
      reminder_enqueued_at: reminder_enqueued_at,
      reminder_sent_at: reminder_sent_at
    )
  end
end
