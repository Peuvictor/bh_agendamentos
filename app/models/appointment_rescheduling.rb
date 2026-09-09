# frozen_string_literal: true

class AppointmentRescheduling < ApplicationRecord
  belongs_to :appointment
  belongs_to :actor, class_name: 'User'

  validates :previous_start_time, :previous_end_time, :new_start_time, :new_end_time, presence: true
  validate :valid_intervals

  after_create_commit :notify_participants

  def readonly?
    persisted?
  end

  private

  def valid_intervals
    return if [previous_start_time, previous_end_time, new_start_time, new_end_time].any?(&:blank?)
    return if previous_start_time < previous_end_time && new_start_time < new_end_time

    errors.add(:base, 'Os intervalos do reagendamento devem ter duração positiva.')
  end

  def notify_participants
    [appointment.client, appointment.service.user].uniq(&:email).each do |recipient|
      AppointmentMailer.rescheduling_email(self, recipient).deliver_later
    end
  end
end
