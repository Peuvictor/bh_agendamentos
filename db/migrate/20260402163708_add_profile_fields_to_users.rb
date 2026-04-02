class AddProfileFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :telefone, :string
    add_column :users, :bio, :text
    add_column :users, :endereco, :string
  end
end
