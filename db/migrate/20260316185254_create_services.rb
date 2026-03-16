class CreateServices < ActiveRecord::Migration[7.1]
  def change
    create_table :services, id: :uuid do |t|
      t.string :nome
      t.text :descricao
      t.integer :duracao_minutos
      t.decimal :preco, precision: 10, scale: 2
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
