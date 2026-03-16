class Appointment < ApplicationRecord
  belongs_to :client, class_name: 'User'
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
    # Busca agendamentos do MESMO serviço que estejam confirmados e que batam no mesmo horário
    overlapping = Appointment.where(service_id: service_id, status: :confirmado)
                             .where.not(id: id) # Ignora a si mesmo na hora de editar
                             .where("start_time < ? AND end_time > ?", end_time, start_time)

    if overlapping.exists?
      errors.add(:base, "Esse horário já está reservado.")
    end
  end
end
