# frozen_string_literal: true

require 'test_helper'

class WebhookDeliveryTest < ActiveSupport::TestCase
  test 'maps delivery statuses and accepts an optional payment' do
    delivery = WebhookDelivery.new(status: :processed)

    assert_predicate delivery, :status_processed?
    assert_nil delivery.payment
  end

  # rubocop:disable-next Minitest/MultipleAssertions
  test 'validates provider, response status, duration and bounded metadata' do
    delivery = WebhookDelivery.new(
      provider: 'other',
      response_status: 99,
      duration_ms: -1,
      resource_id: 'a' * 256
    )

    assert_not_predicate delivery, :valid?
    assert_predicate delivery.errors[:provider], :present?
    assert_predicate delivery.errors[:response_status], :present?
    assert_predicate delivery.errors[:duration_ms], :present?
    assert_predicate delivery.errors[:resource_id], :present?
  end
end
