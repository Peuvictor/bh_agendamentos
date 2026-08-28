# frozen_string_literal: true

require 'test_helper'

# Batch membership, ordering, limit and queue are one behavior of the sweep.
# rubocop:disable-next Metrics/BlockLength, Minitest/MultipleAssertions
class ExpireAppointmentsSweepJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  test 'enqueues overdue pending appointments in batches of one hundred' do
    appointments = 101.times.map do |index|
      Appointment.create!(
        client: users(:two),
        service: services(:one),
        start_time: (index + 10).days.from_now.change(hour: 10, min: 0),
        expires_at: (index + 1).minutes.ago
      )
    end
    future = Appointment.create!(
      client: users(:two),
      service: services(:one),
      start_time: 120.days.from_now.change(hour: 10, min: 0),
      expires_at: 5.minutes.from_now
    )
    cancelled = Appointment.create!(
      client: users(:two),
      service: services(:one),
      start_time: 121.days.from_now.change(hour: 10, min: 0),
      expires_at: 1.minute.ago
    )
    cancelled.update!(status: :cancelado)

    assert_enqueued_jobs 101, only: ExpireAppointmentJob do
      ExpireAppointmentsSweepJob.perform_now
    end

    enqueued_ids = enqueued_jobs.filter_map do |job|
      job[:args].first if job[:job] == ExpireAppointmentJob
    end
    expected_ids = appointments.map(&:id)

    assert_equal expected_ids.sort, enqueued_ids.sort
    assert_not_includes enqueued_ids, future.id
    assert_not_includes enqueued_ids, cancelled.id
    assert_equal 'maintenance', ExpireAppointmentJob.queue_name
    assert_equal 'maintenance', ExpireAppointmentsSweepJob.queue_name
  end
end
