class ChangeDefaultAppointmentStatusToPending < ActiveRecord::Migration[7.1]
  def change
    change_column_default :appointments, :status, from: 0, to: 2
  end
end
