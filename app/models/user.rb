class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { client: 0, admin: 1, provider: 2 }

  has_one_attached :avatar

  has_many :services, dependent: :destroy

  has_many :appointments, dependent: :destroy

  has_many :appointments, foreign_key: 'client_id', dependent: :destroy
end
