# frozen_string_literal: true

class ProviderScheduleUpdater
  attr_reader :error

  def initialize(provider:)
    @provider = provider
  end

  def call(raw_schedule)
    attributes = period_attributes(raw_schedule)

    AvailabilityPeriod.transaction do
      @provider.availability_periods.delete_all
      attributes.each { |attributes_for_period| @provider.availability_periods.create!(attributes_for_period) }
    end

    true
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    @error = e.is_a?(ActiveRecord::RecordInvalid) ? e.record.errors.full_messages.to_sentence : e.message
    false
  end

  private

  def period_attributes(raw_schedule)
    schedule = raw_schedule.to_h

    (0..6).flat_map do |weekday|
      periods_for(schedule[weekday.to_s], weekday)
    end
  end

  def periods_for(day_schedule, weekday)
    periods = day_schedule.to_h.fetch('periods', {}).to_h
    periods.values.filter_map { |period| attributes_for(period, weekday) }
  end

  def attributes_for(period, weekday)
    start_value, end_value = period.to_h.values_at('start', 'end').map(&:to_s)
    return if start_value.blank? && end_value.blank?

    raise ArgumentError, 'Preencha o início e o fim de cada período' if start_value.blank? || end_value.blank?

    {
      weekday: weekday,
      start_minute: AvailabilityPeriod.minute_from_time(start_value),
      end_minute: AvailabilityPeriod.minute_from_time(end_value)
    }
  end
end
