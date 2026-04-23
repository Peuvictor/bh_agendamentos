class Service < ApplicationRecord
  belongs_to :user
  has_many :appointments, dependent: :destroy

  # 1. A PREPARAÇÃO PARA NUVEM (Active Storage + Cloudinary)
  has_one_attached :photo

  # 2. BLINDAGEM DE DADOS
  validates :nome, presence: true, length: { minimum: 3 }
  validates :preco, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Adicione esta linha para criar a ponte
has_many :reviews, through: :appointments


  # 3. VALIDAÇÃO DE TEMPO OFICIAL
  # Agora usamos apenas a coluna 'duration', obrigatória e sempre maior que zero.
  validates :duration, presence: true, numericality: { greater_than: 0 }
end
