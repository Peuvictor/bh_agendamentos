# frozen_string_literal: true

require 'test_helper'

class CreateWebhookDeliveriesTest < ActiveSupport::TestCase
  test 'creates the webhook delivery audit fields and indexes' do
    columns = WebhookDelivery.columns_hash
    indexes = ActiveRecord::Base.connection.indexes(:webhook_deliveries)

    assert_includes columns.keys, 'gateway_request_id'
    assert_includes columns.keys, 'completed_at'
    assert(indexes.any? { |index| index.columns == %w[status created_at] })
  end
end
