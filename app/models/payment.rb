class Payment < ApplicationRecord
  belongs_to :appointment

  enum :status, {
    pendente: 0,
    aprovado: 1,
    rejeitado: 2,
    cancelado: 3,
    reembolsado: 4
  }, default: :pendente

  validates :appointment_id, uniqueness: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :mp_transaction_id, presence: true, uniqueness: true
  validates :idempotency_key, presence: true, uniqueness: true

  before_save :clear_expiration_for_terminal_status

  private

  def clear_expiration_for_terminal_status
    self.expires_at = nil unless pendente?
  end
end
