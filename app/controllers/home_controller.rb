class HomeController < ApplicationController
  # A Home deve ser leve e apenas exibir dados
  def index
    # Removemos a lógica de update_column daqui!
    # Agora, novos usuários permanecerão como 'client' (valor 0) por padrão.

    @services = Service.all.includes(:user)
  end
end
