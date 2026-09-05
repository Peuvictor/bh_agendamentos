# frozen_string_literal: true

class AddArchivingToServices < ActiveRecord::Migration[7.1]
  def change
    change_table :services, bulk: true do |table|
      table.datetime :archived_at
      table.boolean :archived_by_admin, default: false, null: false
      table.index :archived_at
    end
  end
end
