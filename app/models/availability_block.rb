# frozen_string_literal: true

class AvailabilityBlock < ApplicationRecord
  belongs_to :provider, class_name: 'User', inverse_of: :availability_blocks
  belongs_to :service, optional: true

  validates :starts_at, :ends_at, presence: true
  validates :reason, length: { maximum: 150 }
  validate :ends_after_start
  validate :service_belongs_to_provider
  validate :service_is_active, on: :create

  scope :active_from, ->(time) { where(ends_at: time..) }

  def all_services?
    service_id.nil?
  end

  private

  def ends_after_start
    return if starts_at.blank? || ends_at.blank? || starts_at < ends_at

    errors.add(:ends_at, 'deve ser posterior ao início')
  end

  def service_belongs_to_provider
    return if service.blank? || provider.blank? || service.user_id == provider_id

    errors.add(:service, 'deve pertencer ao prestador')
  end

  def service_is_active
    return unless service&.archived?

    errors.add(:service, 'está arquivado')
  end
end
