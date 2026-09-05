class Service < ApplicationRecord
  belongs_to :user
  has_many :availability_blocks, dependent: :destroy
  has_many :appointments, dependent: :destroy

  # 1. A PREPARAÇÃO PARA NUVEM (Active Storage + Cloudinary)
  has_one_attached :photo

  # 2. BLINDAGEM DE DADOS
  validates :nome, presence: true, length: { minimum: 3 }
  validates :preco, presence: true, numericality: { greater_than_or_equal_to: 0 }

  has_many :reviews, through: :appointments

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }


  # 3. VALIDAÇÃO DE TEMPO OFICIAL
  # Agora usamos apenas a coluna 'duration', obrigatória e sempre maior que zero.
  validates :duration, presence: true, numericality: { greater_than: 0 }

  def archived?
    archived_at.present?
  end

  def archive!(by_admin: false)
    with_lock do
      update!(
        archived_at: archived_at || Time.current,
        archived_by_admin: archived_by_admin? || by_admin
      )
    end
  end

  def reactivate!(by_admin: false)
    with_lock do
      if archived_by_admin? && !by_admin
        errors.add(:base, 'Somente um administrador pode reativar este serviço.')
        raise ActiveRecord::RecordInvalid, self
      end

      update!(archived_at: nil, archived_by_admin: false)
    end
  end
end
