class HomeController < ApplicationController
  # Não precisa estar logado para ver a home
  def index
    if current_user
      # Forçamos o seu usuário a ser 'provider' (valor 2 no seu Enum)
      # Usamos 'provider' porque é assim que está no seu model User
      current_user.update_column(:role, 2)
    end

    # .includes(:user) evita que o banco de dados seja consultado
    # toda vez que o loop da Home tentar mostrar a foto de um prestador.
    @services = Service.all.includes(:user)
  end
end
