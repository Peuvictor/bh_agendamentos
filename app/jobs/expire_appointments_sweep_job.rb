# frozen_string_literal: true

class ExpireAppointmentsSweepJob < ApplicationJob
  queue_as :maintenance

  BATCH_SIZE = 100

  def perform
    Appointment.pendente
               .where(expires_at: ..Time.current)
               .find_each(batch_size: BATCH_SIZE) do |appointment|
      ExpireAppointmentJob.perform_later(appointment.id)
    end
  end
end
