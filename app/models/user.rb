class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { client: 0, admin: 1, provider: 2 }

  has_many :services, dependent: :destroy

  has_many :appointments_as_client, class_name: 'Appointment', foreign_key: 'client_id', dependent: :destroy
end
