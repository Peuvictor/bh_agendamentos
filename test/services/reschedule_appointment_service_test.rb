# frozen_string_literal: true

require 'test_helper'
require_relative '../support/rescheduling_setup'

# rubocop:disable Minitest/MultipleAssertions
# rubocop:disable-next Metrics/ClassLength
class RescheduleAppointmentServiceTest < ActiveSupport::TestCase
  include ReschedulingSetup
  include ActionMailer::TestHelper

  setup do
    @appointment = create_paid_appointment
  end

  test 'preserves the purchase and duration while recording the author and both intervals' do
    previous = @appointment.attributes
    payment = @appointment.payment.attributes
    @appointment.service.update!(duration: 90, preco: 100)

    assert rescheduler(@appointment).call
    change = @appointment.reschedulings.sole

    assert_equal previous.fetch('start_time'), change.previous_start_time
    assert_equal previous.fetch('end_time'), change.previous_end_time
    assert_equal users(:two), change.actor
    assert_equal 30.minutes, @appointment.end_time - @appointment.start_time
    assert_equal payment, @appointment.payment.reload.attributes
    assert_predicate @appointment.reload, :confirmado?
  end

  test 'the provider can reschedule and the previous slot becomes available' do
    old_start = @appointment.start_time

    assert rescheduler(@appointment, actor: users(:one)).call
    availability = ProviderAvailability.new(service: @appointment.service, date: old_start.to_date)

    assert availability.available?(old_start)
    assert_not availability.available?(@appointment.start_time)
  end

  test 'rejects another actor without history or notification' do
    stranger = User.create!(nome: 'Terceiro', email: 'third@example.com', password: 'password123')

    assert_no_enqueued_emails do
      assert_no_difference('AppointmentRescheduling.count') do
        assert_not rescheduler(@appointment, actor: stranger).call
      end
    end
  end

  test 'rejects pending canceled refunded and unpaid appointments' do
    %i[pendente cancelado reembolsado].each do |status|
      @appointment.update!(status: status)

      assert_not rescheduler(@appointment).call
    end
    @appointment.update!(status: :confirmado)
    @appointment.payment.update!(status: :pendente)

    assert_not rescheduler(@appointment).call
  end

  test 'rejects archived started and invalid legacy intervals' do
    @appointment.service.archive!

    assert_not rescheduler(@appointment).call
    @appointment.service.reactivate!

    travel_to @appointment.start_time do
      assert_not rescheduler(@appointment).call
    end
    # Simulate legacy data with an interval that current creation callbacks cannot produce.
    # rubocop:disable-next Rails/SkipsModelValidations
    @appointment.update_columns(end_time: @appointment.start_time)

    assert_not rescheduler(@appointment).call
  end

  test 'rejects past malformed off-grid closed and unchanged times' do
    ['bad', '25:00', '14:15', '07:00', '10:00'].each do |hour|
      assert_not rescheduler(@appointment, hour: hour).call
      @appointment.reload
    end

    assert_not rescheduler(@appointment, date: '2026-02-30').call
    assert_not rescheduler(@appointment, date: Date.yesterday.iso8601).call
  end

  test 'rejects service blocks general blocks and days without working periods' do
    start = @appointment.start_time.change(hour: 14)
    [@appointment.service, nil].each do |service|
      block = users(:one).availability_blocks.create!(service: service, starts_at: start, ends_at: start + 1.hour)

      assert_not rescheduler(@appointment).call
      @appointment.reload
      block.destroy!
    end
    users(:one).availability_periods.where(weekday: start.wday).delete_all

    assert_not rescheduler(@appointment).call
  end

  test 'rejects conflicts with another service of the same provider' do
    other_service = users(:one).services.create!(nome: 'Outro serviço', duration: 30, preco: 10)
    create_paid_appointment(service: other_service, hour: 14)
    original = @appointment.start_time

    assert_no_difference('AppointmentRescheduling.count') do
      assert_not rescheduler(@appointment).call
    end
    assert_equal original, @appointment.reload.start_time
  end

  test 'can move into a slot overlapping its own previous interval' do
    @appointment.service.update!(duration: 60)
    # Simulate legacy data with an interval that current creation callbacks cannot produce.
    # rubocop:disable-next Rails/SkipsModelValidations
    @appointment.update_columns(end_time: @appointment.start_time + 60.minutes)

    assert rescheduler(@appointment, hour: '10:30').call
  end

  test 'rejects stale repeated missing and tampered tokens without duplicate history' do
    original_token = @appointment.schedule_token

    assert rescheduler(@appointment, token: original_token).call
    [original_token, '', 'tampered'].each do |token|
      service = rescheduler(@appointment, token: token, hour: '15:00')
      assert_no_difference('AppointmentRescheduling.count') do
        assert_no_enqueued_emails { assert_not service.call }
      end
      assert_predicate service, :stale?
    end
  end

  test 'history validation failure rolls back the new interval and does not enqueue mail' do
    original = @appointment.start_time
    invalid_history = AppointmentRescheduling.new
    invalid_history.errors.add(:base, 'Falha de histórico')
    service = rescheduler(@appointment)

    service.stub(:record_change!, ->(*) { raise ActiveRecord::RecordInvalid, invalid_history }) do
      assert_no_enqueued_emails { assert_not service.call }
    end

    assert_equal original, @appointment.reload.start_time
    assert_empty @appointment.reschedulings
  end

  test 'saved history cannot be edited or deleted through the model' do
    service = rescheduler(@appointment)

    assert service.call
    assert_raises(ActiveRecord::ReadOnlyRecord) { service.rescheduling.update!(new_start_time: Time.current) }
    assert_raises(ActiveRecord::ReadOnlyRecord) { service.rescheduling.destroy! }
  end

  test 'status changes retain the reserved duration after service edits' do
    end_time = @appointment.end_time
    @appointment.service.update!(duration: 120)
    @appointment.update!(status: :cancelado)

    assert_equal end_time, @appointment.reload.end_time
  end
end

# rubocop:enable Minitest/MultipleAssertions
