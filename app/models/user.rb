class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # 1. CONSTANTES GEOGRÁFICAS (MAPA DE BH)
  # Agrupado por região para facilitar a UX no frontend
  BAIRROS_POR_REGIAO = {
    "Centro-Sul" => ["Anchieta", "Belvedere", "Centro", "Coração de Jesus", "Cruzeiro", "Grajaú", "Lourdes", "Prado", "Santo Antônio", "Savassi", "São Pedro", "Sion"],
    "Pampulha" => ["Bandeirantes", "Castelo", "Itatiaia", "Ouro Preto", "Paquetá", "Pampulha", "Santa Terezinha", "São Luiz"],
    "Oeste" => ["Betânia", "Buritis", "Calafate", "Estoril", "Gutierrez", "Havaí", "Palmeiras"],
    "Noroeste" => ["Alípio de Melo", "Caiçara", "Castelo", "Coqueiros", "Padre Eustáquio", "Pindorama"],
    "Nordeste" => ["Cidade Nova", "Concórdia", "Fernão Dias", "Ipiranga", "Palmares", "Sagrada Família"],
    "Leste" => ["Esplanada", "Floresta", "Horto", "Santa Efigênia", "Santa Tereza"],
    "Norte/Venda Nova" => ["Itapoã", "Jaqueline", "Planalto", "Santa Mônica", "Venda Nova"],
    "Barreiro" => ["Barreiro", "Cardoso", "Milionários", "Tirol"]
  }.freeze

  # Gera uma lista única e ordenada para validação
  BAIRROS_BH = BAIRROS_POR_REGIAO.values.flatten.sort.freeze

  # 2. ENUMS
  enum :role, { client: 0, admin: 1, provider: 2 }

  # 3. ASSOCIAÇÕES
  has_one_attached :avatar
  has_many :services, dependent: :destroy
  has_many :appointments, foreign_key: 'client_id', dependent: :destroy
  has_many :received_appointments, through: :services, source: :appointments

  # 4. VALIDAÇÕES SÊNIOR
  # Garante que o bairro seja um dos oficiais da nossa lista
  validates :bairro, inclusion: { in: BAIRROS_BH, message: "deve ser um bairro válido de BH, uai!" }, allow_blank: true
end
