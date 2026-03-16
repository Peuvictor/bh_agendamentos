require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BhAgendamentos
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    config.autoload_lib(ignore: %w(assets tasks))

    # 👇 A MÁGICA DO UUID ENTRA AQUI 👇
    # Força o Rails a usar UUID como chave primária em todas as tabelas geradas
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end
    # 👆 ============================= 👆

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
