# frozen_string_literal: true

class AddExpirationToAppointmentsAndPayments < ActiveRecord::Migration[7.1]
  MINIMUM_EXPIRATION_MINUTES = 30

  def up
    add_expiration_columns
    add_index :appointments, %i[status expires_at]
    add_index :payments, %i[status expires_at]
    backfill_pending_expirations
  end

  def add_expiration_columns
    change_table :appointments, bulk: true do |table|
      table.datetime :expires_at
      table.datetime :expired_at
    end
    change_table :payments, bulk: true do |table|
      table.datetime :expires_at
      table.datetime :expired_at
    end
  end

  def down
    remove_index :payments, %i[status expires_at]
    remove_index :appointments, %i[status expires_at]

    change_table :payments, bulk: true do |table|
      table.remove :expired_at, :expires_at
    end
    change_table :appointments, bulk: true do |table|
      table.remove :expired_at, :expires_at
    end
  end

  private

  def backfill_pending_expirations
    minutes = Integer(ENV.fetch('PAYMENT_EXPIRATION_MINUTES', MINIMUM_EXPIRATION_MINUTES.to_s), 10)
    raise ArgumentError, 'PAYMENT_EXPIRATION_MINUTES must be at least 30' if minutes < MINIMUM_EXPIRATION_MINUTES

    interval = connection.quote("#{minutes} minutes")
    backfill_payments(interval)
    backfill_appointments_with_payments(interval)
    backfill_appointments_without_payments(interval)
  end

  def backfill_payments(interval)
    execute <<~SQL.squish
      UPDATE payments
      SET expires_at = payments.created_at + #{interval}::interval
      FROM appointments
      WHERE payments.appointment_id = appointments.id
        AND payments.status = 0
        AND appointments.status = 2
    SQL
  end

  def backfill_appointments_with_payments(interval)
    execute <<~SQL.squish
      UPDATE appointments
      SET expires_at = payments.created_at + #{interval}::interval
      FROM payments
      WHERE payments.appointment_id = appointments.id
        AND payments.status = 0
        AND appointments.status = 2
    SQL
  end

  def backfill_appointments_without_payments(interval)
    execute <<~SQL.squish
      UPDATE appointments
      SET expires_at = appointments.created_at + #{interval}::interval
      WHERE appointments.status = 2
        AND NOT EXISTS (
          SELECT 1 FROM payments WHERE payments.appointment_id = appointments.id
        )
    SQL
  end
end
