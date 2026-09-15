# frozen_string_literal: true

module Demo
  class Catalog
    USERS = {
      client: { nome: 'Marina Costa', email: 'cliente-demo@example.com', bairro: 'Savassi' },
      provider: { nome: 'Rafael Almeida', email: 'prestador-demo@example.com', bairro: 'Savassi' },
      admin: { nome: 'Administrador Demo', email: 'admin-demo@example.com', bairro: 'Centro' }
    }.freeze
    SERVICES = {
      haircut_beard: ['Corte e barba', 'Corte personalizado e barba com acabamento à navalha.', 85],
      beard: ['Barba e cuidado facial', 'Toalha quente, acabamento e hidratação da barba.', 55],
      haircut: ['Corte clássico', 'Estilo e praticidade para o dia a dia.', 50],
      archived: ['Pacote especial', 'Oferta sazonal encerrada.', 120]
    }.freeze

    attr_reader :users, :services

    def initialize(passwords)
      @passwords = passwords
    end

    def call
      @users = USERS.to_h { |role, attributes| [role, create_user(role, attributes)] }
      @services = SERVICES.to_h { |key, attributes| [key, create_service(key, attributes)] }
      self
    end

    private

    def create_user(role, attributes)
      check_email!(role, attributes.fetch(:email))
      existing = User.find_by(id: Records.id("user/#{role}"))
      return existing if existing

      user = Records.create(User, "user/#{role}", attributes.merge(role: role, password: @passwords.fetch(role)))
      configure_schedule(user) if role == :provider
      user
    end

    def check_email!(role, email)
      return unless User.where(email: email).where.not(id: Records.id("user/#{role}")).exists?

      raise Seed::Error, "O e-mail #{email} já pertence a uma conta fora da demonstração."
    end

    def configure_schedule(provider)
      # Replace only the defaults just created by User's callback, never an existing schedule.
      provider.availability_periods.destroy_all
      (1..6).each do |weekday|
        [[480, 720], [840, 1080]].each do |start_minute, end_minute|
          provider.availability_periods.create!(weekday: weekday, start_minute: start_minute, end_minute: end_minute)
        end
      end
    end

    def create_service(key, attributes)
      name, description, price = attributes
      Records.create(Service, "service/#{key}",
                     user: users.fetch(:provider), nome: name, descricao: description, preco: price, duration: 60,
                     archived_at: key == :archived ? Time.current : nil)
    end
  end
end
