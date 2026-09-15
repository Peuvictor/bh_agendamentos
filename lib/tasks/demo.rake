# frozen_string_literal: true

namespace :demo do
  desc 'Cria exemplos de demonstração sem apagar dados; veja docs/demo.md'
  task seed: :environment do
    result = Demo::Seed.new.call
    puts "Dados de demonstração disponíveis para a semana de #{result.week}. Registros existentes preservados."
    Demo::Catalog::USERS.each_key { |role| puts User.find(Demo::Records.id("user/#{role}")).email }
    if result.missing_images.any?
      abort "Fotos pendentes: #{result.missing_images.join(', ')}. Verifique o armazenamento e execute novamente."
    end
    puts 'Fotos disponíveis. Senhas existentes não foram alteradas. Roteiro: docs/demo.md.'
  rescue Demo::Seed::Error => e
    abort e.message
  end
end
