# frozen_string_literal: true

module Demo
  class Seed
    class Error < StandardError; end

    LOCK_ID = 7_264_301_591

    attr_reader :week, :missing_images

    def initialize(env: ENV)
      @env = env
    end

    def call
      passwords = configuration!
      @week = Date.current.next_occurring(:monday)
      with_load_lock do
        load_records(passwords)
        @missing_images = Assets.new.call
      end
      self
    end

    private

    def with_load_lock
      ApplicationRecord.connection_pool.with_connection do |connection|
        connection.execute("SELECT pg_advisory_lock(#{LOCK_ID})")
        begin
          yield
        ensure
          connection.execute("SELECT pg_advisory_unlock(#{LOCK_ID})")
        end
      end
    end

    def configuration!
      raise Error, 'Configure DEMO_SEED_ENABLED=true para executar a carga explícita.' unless
        @env['DEMO_SEED_ENABLED'] == 'true'

      %i[client provider admin].to_h do |role|
        variable = "DEMO_#{role.to_s.upcase}_PASSWORD"
        password = @env[variable].to_s
        validate_password!(variable, password)

        [role, password]
      end
    end

    def validate_password!(variable, password)
      return if Devise.password_length.cover?(password.length) && password.bytesize <= 72 &&
                password.match?(User::PASSWORD_COMPLEXITY)

      raise Error, "Configure #{variable} com #{Devise.password_length.min} a 72 caracteres (máximo de 72 bytes), " \
                   'incluindo maiúscula, minúscula, número e caractere especial.'
    end

    def load_records(passwords)
      ApplicationRecord.transaction(requires_new: true) do
        catalog = Catalog.new(passwords).call
        Scenarios.new(catalog, week).call
      end
    rescue ActiveRecord::RecordInvalid => e
      raise Error, "Carga cancelada; dados existentes preservados. #{e.record.errors.full_messages.join(', ')}"
    end
  end
end
