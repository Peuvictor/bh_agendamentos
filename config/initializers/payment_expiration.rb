# frozen_string_literal: true

minimum_minutes = 30
configured_minutes = Integer(ENV.fetch('PAYMENT_EXPIRATION_MINUTES', minimum_minutes.to_s), 10)

if configured_minutes < minimum_minutes
  raise ArgumentError, "PAYMENT_EXPIRATION_MINUTES must be at least #{minimum_minutes}"
end

Rails.application.config.x.payment_expiration_minutes = configured_minutes
