# frozen_string_literal: true

class AvailabilityBlockForm
  include ActiveModel::Model

  class EndedBlock < StandardError; end

  attr_accessor :date, :all_day, :start_time, :end_time, :service_id, :reason
  attr_reader :block

  def initialize(block, attributes = nil)
    @block = block
    super(attributes || initial_attributes)
  end

  def all_day?
    ActiveModel::Type::Boolean.new.cast(all_day)
  end

  def interval
    day = parsed_day
    return [day, day + 1.day] if all_day?

    [day + AvailabilityPeriod.minute_from_time(start_time).minutes,
     day + AvailabilityPeriod.minute_from_time(end_time).minutes]
  end

  def save
    block.provider.with_schedule_lock do
      block.with_lock do
        raise EndedBlock unless block.editable?

        save_block
      end
    end
  rescue ArgumentError, TypeError
    errors.add(:base, I18n.t('provider.availability_blocks.invalid_period'))
    false
  end

  private

  def parsed_day
    parsed_date = Date.iso8601(date.to_s)
    Time.zone.local(parsed_date.year, parsed_date.month, parsed_date.day)
  end

  def initial_attributes
    times = initial_times
    {
      date: block.starts_at.to_date.iso8601, all_day: block.all_day?,
      start_time: times.first, end_time: times.last,
      service_id: block.service_id, reason: block.reason
    }
  end

  def initial_times
    block.all_day? ? %w[08:00 19:00] : [block.starts_at.strftime('%H:%M'), block.ends_at.strftime('%H:%M')]
  end

  def save_block
    starts_at, ends_at = interval
    validate_editable_interval(starts_at, ends_at)
    return false if errors.any?

    saved = block.update(starts_at: starts_at, ends_at: ends_at, service: selected_service, reason: reason)
    block.errors.full_messages.each { |message| errors.add(:base, message) }
    saved
  end

  def validate_editable_interval(starts_at, ends_at)
    now = Time.current
    errors.add(:base, 'O término deve estar no futuro.') if ends_at <= now
    return if starts_at == block.starts_at || starts_at > now
    return if all_day? && starts_at.to_date == now.to_date

    errors.add(:base, 'O novo início deve estar no futuro ou corresponder a um dia inteiro de hoje.')
  end

  def selected_service
    return if service_id.blank?
    return block.service if service_id.to_s == block.service_id

    block.provider.services.active.find(service_id)
  end
end
