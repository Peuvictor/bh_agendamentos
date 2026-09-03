# frozen_string_literal: true

class AvailabilityPeriod < ApplicationRecord
  DAY_NAMES = %w[Domingo Segunda-feira Terça-feira Quarta-feira Quinta-feira Sexta-feira Sábado].freeze
  DEFAULT_START_MINUTE = 8 * 60
  DEFAULT_END_MINUTE = 19 * 60

  belongs_to :provider, class_name: 'User', inverse_of: :availability_periods

  validates :weekday, inclusion: { in: 0..6 }
  validates :start_minute, :end_minute,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1440 }
  validate :ends_after_start
  validate :periods_must_not_overlap

  scope :ordered, -> { order(:weekday, :start_minute) }

  def self.minute_from_time(value)
    match = value.to_s.match(/\A(\d{2}):(\d{2})\z/)
    raise ArgumentError, 'Horário inválido' unless match

    hour = match[1].to_i
    minute = match[2].to_i
    raise ArgumentError, 'Horário inválido' if hour > 23 || minute > 59

    (hour * 60) + minute
  end

  def self.format_minute(value)
    format('%<hour>02d:%<minute>02d', hour: value / 60, minute: value % 60)
  end

  def start_label
    self.class.format_minute(start_minute)
  end

  def end_label
    self.class.format_minute(end_minute)
  end

  private

  def ends_after_start
    return if start_minute.blank? || end_minute.blank? || start_minute < end_minute

    errors.add(:end_minute, 'deve ser posterior ao início')
  end

  def periods_must_not_overlap
    return unless range_complete?

    errors.add(:base, 'Os períodos do mesmo dia não podem se sobrepor') if overlapping_periods.exists?
  end

  def range_complete?
    [provider, weekday, start_minute, end_minute].all?(&:present?)
  end

  def overlapping_periods
    provider.availability_periods
            .where(weekday: weekday)
            .where('start_minute < ? AND end_minute > ?', end_minute, start_minute)
            .where.not(id: id)
  end
end
