class DefinePedroComoAdmin < ActiveRecord::Migration[7.1]
  def up
    # Busca o seu usuário no banco de produção
    user = User.find_by(email: "peuvictor22@gmail.com")

    if user
      # Força o cargo para Admin (que você confirmou ser o número 1)
      user.update_column(:role, 1)
      puts "✅ Usuário Pedro atualizado para Admin!"
    else
      puts "⚠️ Usuário não encontrado. Crie a conta pelo site primeiro."
    end
  end

  def down
    # Se precisar reverter a migração um dia
    user = User.find_by(email: "peuvictor22@gmail.com")
    user&.update_column(:role, 0)
  end
end
