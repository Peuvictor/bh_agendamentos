# frozen_string_literal: true

class WebhookDelivery < ApplicationRecord
  belongs_to :payment, optional: true

  enum :status, {
    received: 0,
    processed: 1,
    ignored: 2,
    invalid: 3,
    not_found: 4,
    failed: 5
  }, default: :received, prefix: true

  validates :provider, inclusion: { in: %w[mercado_pago] }
  validates :response_status, inclusion: { in: 100..599 }, allow_nil: true
  validates :duration_ms, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true
  validates :gateway_request_id, :rails_request_id, :resource_id, :error_class,
            length: { maximum: 255 }, allow_nil: true
  validates :event_type, :event_action, :service_result, :remote_status, :failure_code,
            length: { maximum: 100 }, allow_nil: true
end
