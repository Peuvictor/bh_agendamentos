# frozen_string_literal: true

class CreateAppointmentReschedulings < ActiveRecord::Migration[7.1]
  # rubocop:disable-next Metrics/MethodLength
  def change
    create_table :appointment_reschedulings, id: :uuid do |t|
      t.references :appointment, null: false, type: :uuid, foreign_key: true
      t.references :actor, null: false, type: :uuid, foreign_key: { to_table: :users }
      t.datetime :previous_start_time, null: false
      t.datetime :previous_end_time, null: false
      t.datetime :new_start_time, null: false
      t.datetime :new_end_time, null: false
      t.datetime :created_at, null: false
    end

    add_check_constraint :appointment_reschedulings, 'previous_start_time < previous_end_time',
                         name: 'reschedulings_valid_previous_range'
    add_check_constraint :appointment_reschedulings, 'new_start_time < new_end_time',
                         name: 'reschedulings_valid_new_range'
  end
end
