# frozen_string_literal: true

require 'test_helper'

class ProviderAvailabilityTest < ActiveSupport::TestCase
  setup do
    @provider = users(:one)
    @service = services(:one)
    @date = next_weekday(1)
    @now = Time.zone.local(@date.year, @date.month, @date.day) - 1.day
    @provider.availability_periods.delete_all
    create_period(weekday: 1, start_time: '08:00', end_time: '12:00')
    create_period(weekday: 1, start_time: '13:00', end_time: '16:00')
  end

  test 'builds slots inside split working periods and respects service duration' do
    @service.update!(duration: 60)

    slots = availability.slots

    assert_equal %w[08:00 08:30 09:00 09:30 10:00 10:30 11:00 13:00 13:30 14:00 14:30 15:00], slots
  end

  test 'removes slots that conflict with another service from the same provider' do
    other_service = @provider.services.create!(nome: 'Outro atendimento', duration: 60, preco: 80)
    Appointment.create!(
      client: users(:two),
      service: other_service,
      start_time: time_at('09:00')
    )

    slots = availability.slots

    assert_not_includes slots, '09:00'
    assert_not_includes slots, '09:30'
    assert_includes slots, '10:00'
  end

  test 'applies a block to every service' do
    @provider.availability_blocks.create!(
      starts_at: time_at('08:30'),
      ends_at: time_at('10:00'),
      reason: 'Imprevisto'
    )

    slots = availability.slots

    assert_includes slots, '08:00'
    assert_includes slots, '10:00'
    assert_empty slots & %w[08:30 09:30]
  end

  test 'applies a service-specific block only to that service' do
    other_service = @provider.services.create!(nome: 'Serviço livre', duration: 30, preco: 70)
    @provider.availability_blocks.create!(
      service: @service,
      starts_at: time_at('08:00'),
      ends_at: time_at('12:00')
    )

    assert_empty availability.slots.grep(/\A(?:08|09|10|11):/)
    assert_includes ProviderAvailability.new(service: other_service, date: @date, now: @now).slots, '09:00'
  end

  test 'aligns a slot with the start of the period that contains it' do
    @provider.availability_periods.delete_all
    create_period(weekday: 1, start_time: '08:00', end_time: '12:00')
    create_period(weekday: 1, start_time: '13:15', end_time: '16:00')

    assert_includes availability.slots, '13:15'
    assert_not availability.available?(time_at('13:30'))
  end

  private

  def availability
    ProviderAvailability.new(service: @service, date: @date, now: @now)
  end

  def create_period(weekday:, start_time:, end_time:)
    @provider.availability_periods.create!(
      weekday: weekday,
      start_minute: AvailabilityPeriod.minute_from_time(start_time),
      end_minute: AvailabilityPeriod.minute_from_time(end_time)
    )
  end

  def next_weekday(weekday)
    days_ahead = (weekday - Date.current.wday) % 7
    Date.current + (days_ahead.zero? ? 7 : days_ahead).days
  end

  def time_at(value)
    minute = AvailabilityPeriod.minute_from_time(value)
    Time.zone.local(@date.year, @date.month, @date.day) + minute.minutes
  end
end
