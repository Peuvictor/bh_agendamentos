class RemoveDuracaoMinutosFromServices < ActiveRecord::Migration[7.1]
  def change
    # Removemos a coluna duracao_minutos da tabela services
    remove_column :services, :duracao_minutos, :integer
  end
end
