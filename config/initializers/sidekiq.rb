Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://redis:6379/1') }

  config.on(:startup) do
    schedule = YAML.safe_load_file(Rails.root.join('config/sidekiq_schedule.yml'))
    Sidekiq::Cron::Job.load_from_hash!(schedule)
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://redis:6379/1') }
end
