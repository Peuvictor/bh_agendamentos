# frozen_string_literal: true

class AddReminderTrackingToAppointments < ActiveRecord::Migration[7.1]
  def up
    change_table :appointments, bulk: true do |table|
      table.datetime :reminder_enqueued_at
      table.datetime :reminder_sent_at
      table.index %i[status start_time],
                  where: 'reminder_sent_at IS NULL',
                  name: 'index_appointments_for_reminder_delivery'
    end
  end

  def down
    remove_index :appointments, name: 'index_appointments_for_reminder_delivery'
    remove_columns :appointments, :reminder_enqueued_at, :reminder_sent_at
  end
end
