# frozen_string_literal: true

class PurgeWebhookDeliveriesJob < ApplicationJob
  queue_as :maintenance

  BATCH_SIZE = 1000

  def perform
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    deleted_count = WebhookDelivery.where(created_at: ...retention_cutoff).in_batches(of: BATCH_SIZE).sum(&:delete_all)

    Rails.logger.info(
      "webhook_delivery_retention deleted_count=#{deleted_count} duration_ms=#{duration_ms(started_at)}"
    )
  end

  private

  def retention_cutoff
    Rails.configuration.x.webhook_event_retention_days.days.ago
  end

  def duration_ms(started_at)
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
  end
end
