class Appointment < ApplicationRecord
  # Dizemos explicitamente que o :client é, na verdade, a classe User
  belongs_to :client, class_name: 'User'
  belongs_to :service

  # Nosso enum de status do PRD
  enum :status, { confirmado: 0, cancelado: 1 }
end
