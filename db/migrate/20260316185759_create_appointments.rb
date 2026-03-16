class CreateAppointments < ActiveRecord::Migration[7.1]
  def change
    create_table :appointments, id: :uuid do |t|
      t.references :client, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :service, null: false, foreign_key: true, type: :uuid
      t.datetime :start_time
      t.datetime :end_time
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
