# frozen_string_literal: true

class AddRefundTrackingToAppointmentsAndPayments < ActiveRecord::Migration[7.1]
  def change
    change_table :appointments, bulk: true do |table|
      table.datetime :refunded_at
    end

    change_table :payments, bulk: true do |table|
      table.datetime :refunded_at
    end
  end
end
