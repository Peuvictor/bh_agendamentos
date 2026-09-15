# frozen_string_literal: true

require 'test_helper'
require_relative '../support/demo_seed_helpers'

class DemoSeedPreservationTest < ActiveSupport::TestCase
  include DemoSeedHelpers

  setup { travel_to Time.zone.local(2026, 9, 15, 12) }
  teardown { travel_back }

  test 'invalid configuration makes no writes' do
    original = demo_snapshot

    [{}, demo_env.merge('DEMO_ADMIN_PASSWORD' => ''), demo_env.merge('DEMO_CLIENT_PASSWORD' => 'á' * 40)].each do |env|
      assert_raises(Demo::Seed::Error) { seed_demo(env: env) }
    end
    assert_equal original, demo_snapshot
  end

  test 'email collision rolls back even users created earlier in the load' do
    users(:one).update!(email: Demo::Catalog::USERS.fetch(:admin).fetch(:email))
    original = demo_snapshot

    assert_raises(Demo::Seed::Error) { seed_demo }
    assert_equal original, demo_snapshot
  end

  test 'reexecution preserves changed examples credentials and unrelated data' do
    external = users(:one).attributes
    seed_demo
    demo_record(User, 'user/client').update!(password: 'a-new-private-password')
    demo_record(Service, 'service/beard').update!(nome: 'Barba personalizada')
    demo_record(Appointment, '2026-09-21/appointment/0').update!(start_time: Time.zone.local(2026, 9, 21, 10))
    demo_record(Appointment, '2026-09-21/appointment/3').update!(status: :cancelado, expired_at: Time.current)
    snapshot = demo_snapshot
    seed_demo

    assert_equal snapshot, demo_snapshot
    assert_equal external, users(:one).reload.attributes
    assert demo_record(User, 'user/client').valid_password?('a-new-private-password')
  end

  test 'changed schedule aborts the next week without partial records' do
    seed_demo
    demo_record(User, 'user/provider').availability_periods.where(weekday: 1).destroy_all
    snapshot = demo_snapshot
    travel 7.days

    assert_raises(Demo::Seed::Error) { seed_demo }
    assert_equal snapshot, demo_snapshot
  end

  test 'reexecution completes missing dependent records without duplicating appointments' do
    seed_demo
    demo_record(Appointment, '2026-09-21/appointment/0').payment.destroy!
    demo_record(Appointment, 'history/0').review.destroy!
    assert_no_difference('Appointment.count') do
      assert_difference({ 'Payment.count' => 1, 'Review.count' => 1 }) { seed_demo }
    end
  end

  test 'archived service aborts the next week without partial records' do
    seed_demo
    demo_record(Service, 'service/haircut').archive!
    snapshot = demo_snapshot
    travel 7.days

    assert_raises(Demo::Seed::Error) { seed_demo }
    assert_equal snapshot, demo_snapshot
  end

  test 'an existing appointment prevents insertion of a conflicting general block' do
    seed_demo
    Appointment.create!(service: demo_record(Service, 'service/haircut'), client: users(:two),
                        start_time: Time.zone.local(2026, 9, 28, 15), status: :confirmado)
    snapshot = demo_snapshot
    travel 7.days

    assert_raises(Demo::Seed::Error) { seed_demo }
    assert_equal snapshot, demo_snapshot
  end
end
