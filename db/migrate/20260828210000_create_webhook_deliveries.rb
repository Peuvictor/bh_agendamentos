# frozen_string_literal: true

class CreateWebhookDeliveries < ActiveRecord::Migration[7.1]
  # rubocop:disable-next Metrics/AbcSize, Metrics/MethodLength
  def change
    create_table :webhook_deliveries, id: :uuid do |table|
      table.string :provider, limit: 50, null: false, default: 'mercado_pago'
      table.string :gateway_request_id, limit: 255
      table.string :rails_request_id, limit: 255
      table.string :event_type, limit: 100
      table.string :event_action, limit: 100
      table.string :resource_id, limit: 255
      table.references :payment, type: :uuid, foreign_key: { on_delete: :nullify }
      table.integer :status, null: false, default: 0
      table.string :service_result, limit: 100
      table.string :remote_status, limit: 100
      table.string :failure_code, limit: 100
      table.string :error_class, limit: 255
      table.integer :response_status
      table.integer :duration_ms
      table.datetime :completed_at
      table.timestamps
    end

    add_index :webhook_deliveries, :gateway_request_id
    add_index :webhook_deliveries, :resource_id
    add_index :webhook_deliveries, %i[status created_at]
  end
end
