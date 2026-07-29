class CreatePayments < ActiveRecord::Migration[7.1]
  def change
    create_table :payments, id: :uuid do |t|
      t.references :appointment, null: false, foreign_key: true, type: :uuid
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :status, default: 0, null: false
      t.string :mp_transaction_id
      t.string :idempotency_key

      t.timestamps
    end

    add_index :payments, :idempotency_key, unique: true
  end
end
