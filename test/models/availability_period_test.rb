# frozen_string_literal: true

require 'test_helper'

class AvailabilityPeriodTest < ActiveSupport::TestCase
  test 'converts form times to minutes and formats them' do
    assert_equal 510, AvailabilityPeriod.minute_from_time('08:30')
    assert_equal '13:05', AvailabilityPeriod.format_minute(785)
  end

  test 'rejects overlapping periods for the same provider and weekday' do
    provider = users(:one)
    provider.availability_periods.where(weekday: 1).delete_all
    provider.availability_periods.create!(weekday: 1, start_minute: 480, end_minute: 720)
    overlapping = provider.availability_periods.build(weekday: 1, start_minute: 660, end_minute: 900)

    assert_not overlapping.valid?
    assert_includes overlapping.errors[:base], 'Os períodos do mesmo dia não podem se sobrepor'
  end
end
