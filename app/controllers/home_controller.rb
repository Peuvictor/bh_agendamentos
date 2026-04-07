class HomeController < ApplicationController
  # Não precisa estar logado para ver a home
 def index
  if current_user
    # Tenta atualizar de duas formas para garantir
    current_user.update_column(:role, "prestador")
    # Se o seu Enum for por número (0 = cliente, 1 = prestador), tente a linha abaixo:
    # current_user.update_column(:role, 1)
  end

  @services = Service.all
end
end
