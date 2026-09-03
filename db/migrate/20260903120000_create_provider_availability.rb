# frozen_string_literal: true

class CreateProviderAvailability < ActiveRecord::Migration[7.1]
  LEGACY_OPENING_MINUTE = 8 * 60
  LEGACY_CLOSING_MINUTE = 19 * 60

  def up
    create_availability_periods
    create_availability_blocks
    backfill_existing_providers
  end

  def down
    drop_table :availability_blocks
    drop_table :availability_periods
  end

  private

  def create_availability_periods
    create_table :availability_periods, id: :uuid do |table|
      table.references :provider, null: false, type: :uuid, foreign_key: { to_table: :users }
      table.integer :weekday, null: false
      table.integer :start_minute, null: false
      table.integer :end_minute, null: false
      table.timestamps
    end

    add_availability_period_index
    add_availability_period_constraints
  end

  def add_availability_period_index
    add_index :availability_periods,
              %i[provider_id weekday start_minute end_minute],
              unique: true,
              name: 'index_availability_periods_on_provider_and_range'
  end

  def add_availability_period_constraints
    add_check_constraint :availability_periods,
                         'weekday BETWEEN 0 AND 6',
                         name: 'availability_periods_valid_weekday'
    add_check_constraint :availability_periods,
                         'start_minute >= 0 AND end_minute <= 1440 AND start_minute < end_minute',
                         name: 'availability_periods_valid_minutes'
  end

  def create_availability_blocks
    create_table :availability_blocks, id: :uuid do |table|
      table.references :provider, null: false, type: :uuid, foreign_key: { to_table: :users }
      table.references :service, null: true, type: :uuid, foreign_key: true
      table.datetime :starts_at, null: false
      table.datetime :ends_at, null: false
      table.string :reason, limit: 150
      table.timestamps
    end

    add_availability_block_indexes
    add_availability_block_constraint
  end

  def add_availability_block_indexes
    add_index :availability_blocks, %i[provider_id starts_at ends_at]
    add_index :availability_blocks, %i[service_id starts_at ends_at]
  end

  def add_availability_block_constraint
    add_check_constraint :availability_blocks,
                         'starts_at < ends_at',
                         name: 'availability_blocks_valid_range'
  end

  def backfill_existing_providers
    now = connection.quote(Time.current)

    (0..6).each do |weekday|
      execute <<~SQL.squish
        INSERT INTO availability_periods
          (provider_id, weekday, start_minute, end_minute, created_at, updated_at)
        SELECT id, #{weekday}, #{LEGACY_OPENING_MINUTE}, #{LEGACY_CLOSING_MINUTE}, #{now}, #{now}
        FROM users
        WHERE role = 2
      SQL
    end
  end
end
