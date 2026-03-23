class Appointment < ApplicationRecord
  belongs_to :client, class_name: 'User', foreign_key: 'client_id'
  belongs_to :service

  enum :status, { confirmado: 0, cancelado: 1 }

  validates :start_time, presence: true
  validate :no_overlapping_appointments

  # Callback: calcula o fim antes de validar e salvar
  before_validation :calculate_end_time

  private

  def calculate_end_time
    return unless start_time && service
    # AJUSTE: Usando 'duracao_minutos' que é o nome real da sua coluna
    self.end_time = start_time + service.duracao_minutos.minutes
  end

  def no_overlapping_appointments
    return if start_time.blank? || end_time.blank?

    # Busca conflitos apenas para o mesmo serviço
    overlapping = Appointment.where(service_id: service_id)
                             .where.not(status: :cancelado)
                             .where.not(id: id)
                             .where("start_time < ? AND end_time > ?", end_time, start_time)

    if overlapping.exists?
      errors.add(:base, "Ops! Este horário já está ocupado para este serviço aqui em BH.")
    end
  end
end
