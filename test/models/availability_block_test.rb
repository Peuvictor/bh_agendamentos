# frozen_string_literal: true

require 'test_helper'

class AvailabilityBlockTest < ActiveSupport::TestCase
  test 'rejects a service owned by another provider' do
    block = AvailabilityBlock.new(
      provider: users(:one),
      service: services(:two),
      starts_at: 1.day.from_now,
      ends_at: 2.days.from_now
    )

    assert_not block.valid?
    assert_includes block.errors[:service], 'deve pertencer ao prestador'
  end

  test 'accepts a block for all provider services' do
    block = AvailabilityBlock.new(
      provider: users(:one),
      starts_at: 1.day.from_now,
      ends_at: 2.days.from_now
    )

    assert_predicate block, :valid?
    assert_predicate block, :all_services?
  end
end
