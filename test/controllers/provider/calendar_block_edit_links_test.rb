# frozen_string_literal: true

require 'test_helper'

module Provider
  class CalendarBlockEditLinksTest < ActionDispatch::IntegrationTest
    test 'only non ended blocks expose editing links' do
      provider = users(:one)
      ended = provider.availability_blocks.create!(starts_at: 2.hours.ago, ends_at: 1.hour.ago)
      ongoing = provider.availability_blocks.create!(starts_at: 1.hour.ago, ends_at: 1.hour.from_now)
      sign_in provider
      get provider_calendar_events_url, params: { start: 1.day.ago.iso8601, end: 1.day.from_now.iso8601 }, as: :json
      events = response.parsed_body.index_by { |event| event.fetch('id') }

      assert_nil events.fetch("availability-block-#{ended.id}").dig('extendedProps', 'editUrl')
      assert_equal edit_provider_availability_block_path(ongoing),
                   events.fetch("availability-block-#{ongoing.id}").dig('extendedProps', 'editUrl')
    end
  end
end
