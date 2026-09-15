# frozen_string_literal: true

require 'test_helper'
require_relative '../support/demo_seed_helpers'

class DemoSeedLockTest < ActiveSupport::TestCase
  include DemoSeedHelpers

  test 'load retains its database lock through uploads and releases it afterwards' do
    assets = Demo::Assets.new
    assets.stub(:call, lambda {
      assert_not load_lock_available?
      []
    }) do
      Demo::Assets.stub(:new, -> { assets }) { seed_demo(images: true) }
    end

    assert_predicate self, :load_lock_available?
  end

  test 'failed load releases the lock for a later attempt' do
    seed_demo
    demo_record(Service, 'service/beard').archive!

    travel 7.days do
      assert_raises(Demo::Seed::Error) { seed_demo }
    end

    assert_predicate self, :load_lock_available?
  end

  private

  def load_lock_available?
    # Checkout explicitly to avoid the connection pinned to the test transaction.
    connection = ApplicationRecord.connection_pool.checkout
    available = connection.select_value("SELECT pg_try_advisory_lock(#{Demo::Seed::LOCK_ID})")
  ensure
    if connection
      connection.execute("SELECT pg_advisory_unlock(#{Demo::Seed::LOCK_ID})") if available
      ApplicationRecord.connection_pool.checkin(connection)
    end
  end
end
