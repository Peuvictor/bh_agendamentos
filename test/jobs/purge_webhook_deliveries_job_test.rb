# frozen_string_literal: true

require 'test_helper'

class PurgeWebhookDeliveriesJobTest < ActiveJob::TestCase
  include ActiveSupport::Testing::TimeHelpers

  test 'deletes deliveries older than the configured retention period in the maintenance queue' do
    previous_retention_days = Rails.configuration.x.webhook_event_retention_days
    Rails.configuration.x.webhook_event_retention_days = 7
    old_delivery = create_delivery(created_at: 8.days.ago)
    recent_delivery = create_delivery(created_at: 6.days.ago)

    PurgeWebhookDeliveriesJob.perform_now

    assert_not WebhookDelivery.exists?(old_delivery.id)
    assert WebhookDelivery.exists?(recent_delivery.id)
    assert_equal 'maintenance', PurgeWebhookDeliveriesJob.queue_name
  ensure
    Rails.configuration.x.webhook_event_retention_days = previous_retention_days
  end

  private

  def create_delivery(created_at:)
    WebhookDelivery.create!(
      status: :processed,
      response_status: 200,
      completed_at: created_at,
      created_at: created_at,
      updated_at: created_at
    )
  end
end
