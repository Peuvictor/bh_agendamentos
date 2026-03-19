class Appointment < ApplicationRecord
  belongs_to :client, class_name: 'User', foreign_key: 'client_id'
  belongs_to :service

  enum :status, { confirmado: 0, cancelado: 1 }

  # Validações básicas para garantir que os dados não venham vazios
  validates :start_time, :end_time, presence: true
  validate :end_time_after_start_time
  validate :no_overlapping_appointments

  private

  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    if end_time <= start_time
      errors.add(:end_time, "deve ser depois do horário de início")
    end
  end

  def no_overlapping_appointments
  # Verificamos todos os agendamentos que NÃO foram cancelados
  # e que NÃO são o próprio registro (em caso de edição)
  overlapping = Appointment.where.not(status: :cancelado)
                           .where.not(id: id)
                           .where("start_time < ? AND end_time > ?", end_time, start_time)

    if overlapping.exists?
    errors.add(:base, "Ops! Este horário já está ocupado por outro agendamento.")
    end
  end
end
