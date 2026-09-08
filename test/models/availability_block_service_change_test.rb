# frozen_string_literal: true

require 'test_helper'

class AvailabilityBlockServiceChangeTest < ActiveSupport::TestCase
  test 'updates preserve an archived link but cannot select a new archived service' do
    service = services(:one)
    block = service.user.availability_blocks.create!(
      service: service, starts_at: 1.day.from_now, ends_at: 2.days.from_now
    )
    service.archive!

    assert block.update(reason: 'Preservado')
    assert block.update(service: nil)
    assert_not block.update(service: service)
  end
end
