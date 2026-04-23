class Review < ApplicationRecord
  belongs_to :appointment

  # 👇 VALIDAÇÕES SÊNIOR
  # Garante que a nota seja obrigatória e esteja entre 1 e 5
  validates :rating, presence: true, inclusion: { in: 1..5, message: "deve ser entre 1 e 5" }
  validates :comment, length: { maximum: 500 }

  # Impede que o mesmo agendamento seja avaliado mais de uma vez
  validates :appointment_id, uniqueness: { message: "já possui uma avaliação, uai!" }
end
