# frozen_string_literal: true

require 'test_helper'

class SidekiqScheduleTest < ActiveSupport::TestCase
  test 'runs the expiration sweep every minute in the maintenance queue' do
    schedule = YAML.safe_load_file(Rails.root.join('config/sidekiq_schedule.yml'))
    expiration_job = schedule.fetch('expire_pending_appointments')

    assert_equal '* * * * *', expiration_job.fetch('cron')
    assert_equal 'ExpireAppointmentsSweepJob', expiration_job.fetch('class')
    assert_equal 'maintenance', expiration_job.fetch('queue')
  end

  test 'configures Sidekiq to consume the maintenance queue' do
    config = YAML.safe_load_file(Rails.root.join('config/sidekiq.yml'), permitted_classes: [Symbol])

    assert_includes config.fetch(:queues), 'default'
    assert_includes config.fetch(:queues), 'maintenance'
  end
end
