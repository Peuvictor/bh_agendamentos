class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Enum para controle de acesso (0: cliente, 1: admin, 2: prestador)
  enum :role, { client: 0, admin: 1, provider: 2 }

  # Foto de perfil via Active Storage
  has_one_attached :avatar

  # Serviços que o usuário oferece (se for provider)
  has_many :services, dependent: :destroy

  # Agendamentos onde o usuário é o CLIENTE (quem marcou o serviço)
  has_many :appointments, foreign_key: 'client_id', dependent: :destroy

  # Agendamentos onde o usuário é o PRESTADOR (através dos seus serviços)
  # Isso permite que você faça: current_user.received_appointments
  has_many :received_appointments, through: :services, source: :appointments
end
