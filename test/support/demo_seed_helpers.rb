# frozen_string_literal: true

module DemoSeedHelpers
  def demo_env
    { 'DEMO_SEED_ENABLED' => 'true', 'DEMO_CLIENT_PASSWORD' => 'demo-test-password',
      'DEMO_PROVIDER_PASSWORD' => 'demo-test-password', 'DEMO_ADMIN_PASSWORD' => 'demo-test-password' }
  end

  def seed_demo(images: false, env: demo_env)
    return Demo::Seed.new(env: env).call if images

    Demo::Assets.stub(:new, -> { Struct.new(:call).new([]) }) { Demo::Seed.new(env: env).call }
  end

  def demo_record(model, key)
    model.find(Demo::Records.id(key))
  end

  def demo_snapshot(ignore_touch: false)
    [User, Service, Appointment, Payment, Review, AvailabilityBlock, AvailabilityPeriod].to_h do |model|
      rows = model.order(:id).map(&:attributes)
      rows.each { |row| row.delete('updated_at') } if ignore_touch
      [model.name, rows]
    end
  end
end
