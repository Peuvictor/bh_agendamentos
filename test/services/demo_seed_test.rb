# frozen_string_literal: true

require 'test_helper'
require_relative '../support/demo_seed_helpers'

class DemoSeedTest < ActiveSupport::TestCase
  include DemoSeedHelpers
  include ActiveJob::TestHelper

  setup { travel_to Time.zone.local(2026, 9, 15, 12) }
  teardown { travel_back }

  # rubocop:disable-next Minitest/MultipleAssertions
  test 'creates all three private accounts and the catalog' do
    assert_difference({ 'User.count' => 3, 'Service.count' => 4 }) { seed_demo }
    Demo::Catalog::USERS.each_key do |role|
      user = demo_record(User, "user/#{role}")

      assert_equal role.to_s, user.role
      assert user.valid_password?('demo-test-password')
    end
    assert_predicate demo_record(Service, 'service/archived'), :archived?
  end

  # rubocop:disable-next Minitest/MultipleAssertions
  test 'creates final payments and an unpaid pending booking without gateway or mail' do
    MercadoPagoPaymentGateway.stub(:new, ->(*) { flunk 'Gateway must not be constructed' }) do
      assert_no_enqueued_jobs(only: ActionMailer::MailDeliveryJob) do
        assert_difference({ 'Appointment.count' => 8, 'Payment.count' => 6, 'Review.count' => 2 }) { seed_demo }
      end
    end
    pending = demo_record(Appointment, '2026-09-21/appointment/3')

    assert_nil pending.payment
    assert_equal Time.current + Rails.configuration.x.payment_expiration_minutes.minutes, pending.expires_at
    assert_equal %w[aprovado reembolsado], Payment.where("mp_transaction_id LIKE 'demo-%'").distinct.pluck(:status).sort
  end

  # rubocop:disable-next Minitest/MultipleAssertions
  test 'bookings have preserved duration and financial consistency' do
    seed_demo
    appointments = demo_record(User, 'user/client').appointments
    appointments.each do |appointment|
      assert_equal 1.hour, appointment.end_time - appointment.start_time
      next unless appointment.payment

      assert_equal appointment.service.preco, appointment.payment.amount
      assert_equal appointment.reembolsado? ? 'reembolsado' : 'aprovado', appointment.payment.status
    end
    assert_predicate demo_record(Appointment, '2026-09-21/appointment/0'), :reschedulable?
  end

  # rubocop:disable-next Minitest/MultipleAssertions
  test 'creates past reviewed visits only once' do
    seed_demo
    historical = demo_record(Appointment, 'history/0')

    assert_operator historical.end_time, :<, Time.current
    assert_equal 5, historical.review.rating
    assert_predicate historical.payment, :aprovado?
    assert_no_difference('Review.count') { seed_demo }
  end

  # rubocop:disable-next Minitest/MultipleAssertions
  test 'availability reflects two shifts closed Sundays and both block scopes' do
    seed_demo
    beard = demo_record(Service, 'service/beard')
    haircut = demo_record(Service, 'service/haircut')
    monday = Date.new(2026, 9, 21)

    assert_equal 12, beard.user.availability_periods.count
    assert_empty ProviderAvailability.new(service: beard, date: monday - 1).slots
    assert_empty ProviderAvailability.new(service: haircut, date: monday).slots & %w[09:00 11:00 12:00 15:00]
    assert_not_includes ProviderAvailability.new(service: beard, date: monday + 1).slots, '14:00'
    assert_includes ProviderAvailability.new(service: haircut, date: monday + 1).slots, '14:00'
  end

  test 'weekly renewal adds only the new week and keeps original history' do
    seed_demo
    historical = demo_record(Appointment, 'history/0').attributes
    travel 7.days
    assert_difference({ 'Appointment.count' => 6, 'Payment.count' => 4, 'AvailabilityBlock.count' => 2 }) { seed_demo }
    assert_equal historical, demo_record(Appointment, 'history/0').attributes
    assert_equal 2, Review.where(appointment_id: demo_record(User, 'user/client').appointments).count
  end
end
