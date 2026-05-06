# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
require "open-uri"

puts "--- 🧹 Limpando o banco de dados... ---"
# Limpeza rápida
User.destroy_all # O dependent: :destroy nos models deve cuidar do resto

puts "--- 🏗️ Gerando Prestadores em BH (Versão Resiliente) ---"

bairros_bh = User::BAIRROS_POR_REGIAO.values.flatten
service_images = [
  "https://images.unsplash.com/photo-1503951914875-452162b0f3f1?q=80&w=800",
  "https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?q=80&w=800",
  "https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?q=80&w=800"
]

15.times do |i|
  provider = User.create!(
    nome: Faker::Name.name,
    email: "prestador#{i}_#{Time.now.to_i}@teste.com",
    password: "password123",
    role: "provider",
    bairro: bairros_bh.sample,
    telefone: "(31) 9#{Faker::Number.number(digits: 8)}"
  )

  # Foto do Prestador com timeout e rescue
  begin
    avatar_url = "https://i.pravatar.cc/300?u=#{provider.email}"
    provider.avatar.attach(io: URI.open(avatar_url, read_timeout: 5), filename: "avatar.jpg")
  rescue => e
    puts "⚠️ Pulando avatar de #{provider.nome} devido a erro de rede."
  end

  3.times do |j|
    service = Service.create!(
      user: provider,
      nome: "#{Faker::Job.field} Profissional",
      descricao: Faker::Lorem.sentence,
      preco: rand(50..200),
      duration: [30, 45, 60].sample
    )

    # Foto do Serviço com timeout e rescue
    begin
      img_url = service_images.sample
      service.photo.attach(io: URI.open(img_url, read_timeout: 5), filename: "service.jpg")
    rescue => e
      puts "⚠️ Pulando foto do serviço #{service.nome} (Timeout)."
    end
  end
  puts "✅ #{provider.nome} e seus serviços criados!"
end

puts "--- 🚀 Seed finalizado com sucesso! ---"
