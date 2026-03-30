class Appointment < ApplicationRecord
  belongs_to :client, class_name: 'User', foreign_key: 'client_id'
  belongs_to :service

  enum :status, { confirmado: 0, cancelado: 1 }

  validates :start_time, presence: true
  validate :no_overlapping_appointments

  # Callback: calcula o fim antes de validar e salvar
  before_validation :calculate_end_time

  validate :horario_deve_ser_no_futuro

  private

  def calculate_end_time
    return unless start_time && service
    # AJUSTE: Usando 'duracao_minutos' que é o nome real da sua coluna
    self.end_time = start_time + service.duracao_minutos.minutes
  end

 def no_overlapping_appointments
    
    return if start_time.blank? || end_time.blank? || service.blank?

    prestador_id = service.user_id


    servicos_do_prestador_ids = Service.where(user_id: prestador_id).pluck(:id)

    overlapping = Appointment.where(service_id: servicos_do_prestador_ids)
                             .where("start_time < ? AND end_time > ?", end_time, start_time)


    overlapping = overlapping.where.not(id: id) if persisted?

    # 6. A trava final
    if overlapping.exists?
      errors.add(:base, "Ops! O prestador já está atendendo outro cliente neste horário.")
    end
  end
  def horario_deve_ser_no_futuro
    # Se a data/hora existir e for menor que o relógio exato de agora
    if start_time.present? && start_time < Time.current
      errors.add(:start_time, "não pode ser no passado, uai! Escolha um horário válido.")
    end
  end
end
