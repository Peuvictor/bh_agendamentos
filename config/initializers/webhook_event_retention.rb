# frozen_string_literal: true

minimum_days = 7
configured_days = Integer(ENV.fetch('WEBHOOK_EVENT_RETENTION_DAYS', '90'), 10)

raise ArgumentError, "WEBHOOK_EVENT_RETENTION_DAYS must be at least #{minimum_days}" if configured_days < minimum_days

Rails.application.config.x.webhook_event_retention_days = configured_days
