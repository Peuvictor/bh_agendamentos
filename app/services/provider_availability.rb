# frozen_string_literal: true

class ProviderAvailability
  SLOT_INTERVAL_MINUTES = 30

  def initialize(service:, date:, now: Time.current, exclude_appointment: nil)
    @service = service
    @provider = service.user
    @date = date.to_date
    @now = now
    @exclude_appointment = exclude_appointment
  end

  def slots
    return [] if @service.archived?

    periods.flat_map { |period| slots_for(period) }
           .select { |start_time| available?(start_time) }
           .map { |start_time| start_time.strftime('%H:%M') }
           .uniq
  end

  def available?(start_time, check_appointments: true)
    return false if @service.archived?

    finish_time = start_time + duration.minutes

    within_available_period?(start_time, finish_time) &&
      !blocked?(start_time, finish_time) &&
      (!check_appointments || !appointment_conflict?(start_time, finish_time)) &&
      start_time > @now
  end

  private

  def periods
    @periods ||= @provider.availability_periods.where(weekday: @date.wday).ordered
  end

  def slots_for(period)
    period_start = time_at(period.start_minute)
    period_end = time_at(period.end_minute)
    latest_start = period_end - duration.minutes
    return [] if latest_start < period_start

    interval = SLOT_INTERVAL_MINUTES.minutes
    slot_count = ((latest_start - period_start) / interval).floor
    (0..slot_count).map { |index| period_start + (index * interval) }
  end

  def within_available_period?(start_time, finish_time)
    return false unless start_time.to_date == @date

    periods.any? do |period|
      period_start = time_at(period.start_minute)
      offset_seconds = start_time - period_start

      start_time >= period_start &&
        finish_time <= time_at(period.end_minute) &&
        (offset_seconds % SLOT_INTERVAL_MINUTES.minutes).zero?
    end
  end

  def blocked?(start_time, finish_time)
    @provider.availability_blocks
             .where(service_id: [nil, @service.id])
             .exists?(['starts_at < ? AND ends_at > ?', finish_time, start_time])
  end

  def appointment_conflict?(start_time, finish_time)
    appointments = Appointment.joins(:service)
                              .where(services: { user_id: @provider.id })
                              .where.not(status: %i[cancelado reembolsado])
                              .where(
                                'appointments.start_time < ? AND appointments.end_time > ?',
                                finish_time,
                                start_time
                              )
    appointments = appointments.where.not(id: @exclude_appointment.id) if @exclude_appointment&.persisted?
    appointments.exists?
  end

  def time_at(minute)
    Time.zone.local(@date.year, @date.month, @date.day) + minute.minutes
  end

  def duration
    @duration ||= @service.duration.presence || 30
  end
end
