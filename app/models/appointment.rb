class Appointment < ApplicationRecord
  include ReschedulableAppointment
  include RemindableAppointment

  belongs_to :client, class_name: 'User', foreign_key: 'client_id'
  belongs_to :service
  has_one :review, dependent: :destroy
  has_one :payment, dependent: :restrict_with_error
  has_many :reschedulings, class_name: 'AppointmentRescheduling', dependent: :restrict_with_error

  # Enum de status mantido e blindado
  enum :status, { confirmado: 0, cancelado: 1, pendente: 2, reembolsado: 4 }, default: :pendente

  validates :start_time, presence: true
  validate :service_must_be_active, if: :service_availability_validation_required?
  validate :no_overlapping_appointments
  validate :horario_deve_ser_no_futuro
  validate :within_provider_availability, if: :availability_validation_required?

  # Callback: calcula o fim antes de validar e salvar
  before_validation :calculate_end_time
  before_save :clear_expiration_for_terminal_status
  before_create :set_initial_expiration, if: :pendente?

  def save_for_active_service
    return save unless new_record? && service.present?

    service.user.with_schedule_lock do
      service.with_lock do
        save_with_service_check
      end
    end
  end

  private

  def save_with_service_check
    if service.archived?
      errors.add(:service, "está arquivado e não aceita novas reservas")
      false
    else
      save
    end
  end

  def service_must_be_active
    return unless service&.archived?

    errors.add(:service, "está arquivado e não aceita novas reservas")
  end

  def service_availability_validation_required?
    new_record? || will_save_change_to_service_id?
  end

  def set_initial_expiration
    self.expires_at ||= Time.current + Rails.configuration.x.payment_expiration_minutes.minutes
  end

  def clear_expiration_for_terminal_status
    self.expires_at = nil unless pendente?
  end

  def calculate_end_time
    return unless start_time && service
    return unless schedule_changed?

    duration = if service_availability_validation_required?
                 (service.duration || 30).minutes
               else
                 original_duration_seconds
               end
    self.end_time = start_time + duration if duration
  end

  def original_duration_seconds
    return unless start_time_in_database && end_time_in_database

    end_time_in_database - start_time_in_database
  end

  def no_overlapping_appointments
    return unless overlap_validation_required?
    return unless overlapping_appointments.exists?

    errors.add(:base, "Ops! O prestador já está atendendo outro cliente neste horário.")
  end

  def overlap_validation_required?
    return false if cancelado? || reembolsado?

    start_time.present? && end_time.present? && service.present? &&
      (schedule_changed? || will_save_change_to_status?)
  end

  def overlapping_appointments
    Appointment.where(service_id: Service.where(user_id: service.user_id).select(:id))
               .where.not(status: %i[cancelado reembolsado])
               .where('start_time < ? AND end_time > ?', end_time, start_time)
               .where.not(id: id)
  end

  def horario_deve_ser_no_futuro
    # O horário precisa ser futuro ao criar ou reagendar. Alterações de status
    # continuam permitidas depois que o atendimento já aconteceu.
    if start_time.present? && will_save_change_to_start_time? && start_time < Time.current
      errors.add(:start_time, "não pode ser no passado, uai! Escolha um horário válido.")
    end
  end

  def availability_validation_required?
    start_time.present? && service.present? && schedule_changed?
  end

  def schedule_changed?
    new_record? || will_save_change_to_start_time? || will_save_change_to_service_id?
  end

  def within_provider_availability
    availability = ProviderAvailability.new(
      service: service,
      date: start_time.to_date,
      exclude_appointment: self,
      duration: reserved_duration
    )
    return if availability.available?(start_time, check_appointments: false)

    errors.add(:start_time, "não está disponível na agenda do prestador")
  end
end
