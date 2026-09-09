# frozen_string_literal: true

class RescheduleAppointmentService
  class Unavailable < StandardError; end
  class StaleSchedule < StandardError; end

  attr_reader :error, :rescheduling

  def initialize(appointment:, actor:, date:, hour:, schedule_token:)
    @appointment = appointment
    @actor = actor
    @date = date
    @hour = hour
    @schedule_token = schedule_token
    @stale = false
  end

  def call
    with_schedule_locks { reschedule_locked! }
    true
  rescue StaleSchedule => e
    @stale = true
    @error = e.message
    false
  rescue Unavailable, ArgumentError, TypeError, ActiveRecord::RecordInvalid => e
    @error = e.is_a?(ActiveRecord::RecordInvalid) ? e.record.errors.full_messages.to_sentence : e.message
    false
  end

  def stale?
    @stale
  end

  private

  def with_schedule_locks(&operation)
    @appointment.service.user.with_schedule_lock do
      @appointment.service.with_lock do
        @appointment.with_lock(&operation)
      end
    end
  end

  def reschedule_locked!
    payment = @appointment.reload_payment
    payment&.lock!
    validate_eligibility!
    validate_token!
    new_start = parsed_start
    raise Unavailable, 'Escolha um horário diferente do atual.' if new_start == @appointment.start_time

    previous = @appointment.attributes.slice('start_time', 'end_time')
    @appointment.update!(start_time: new_start)
    record_change!(previous)
  end

  def record_change!(previous)
    @rescheduling = @appointment.reschedulings.create!(
      actor: @actor,
      previous_start_time: previous.fetch('start_time'), previous_end_time: previous.fetch('end_time'),
      new_start_time: @appointment.start_time, new_end_time: @appointment.end_time
    )
  end

  def validate_eligibility!
    authorized = [@appointment.client_id, @appointment.service.user_id].include?(@actor.id)
    return if authorized && @appointment.reschedulable?

    raise Unavailable, 'Este agendamento não está disponível para reagendamento.'
  end

  def validate_token!
    return if @appointment.current_schedule_token?(@schedule_token)

    raise StaleSchedule, 'O agendamento foi alterado. Recarregue o formulário antes de tentar novamente.'
  end

  def parsed_start
    date = Date.iso8601(@date.to_s)
    minute = AvailabilityPeriod.minute_from_time(@hour)
    Time.zone.local(date.year, date.month, date.day) + minute.minutes
  rescue ArgumentError
    raise ArgumentError, 'Data ou horário inválido. Verifique os valores informados.'
  end
end
