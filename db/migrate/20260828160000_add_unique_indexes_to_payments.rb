class AddUniqueIndexesToPayments < ActiveRecord::Migration[7.1]
  def up
    remove_index :payments, :appointment_id
    add_index :payments, :appointment_id, unique: true
    add_index :payments, :mp_transaction_id, unique: true
  end

  def down
    remove_index :payments, :mp_transaction_id
    remove_index :payments, :appointment_id
    add_index :payments, :appointment_id
  end
end
