class AddBairroToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :bairro, :string
  end
end
