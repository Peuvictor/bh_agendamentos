class HomeController < ApplicationController
  # Não precisa estar logado para ver a home
 def index
  # TRUQUE TEMPORÁRIO: Promove o seu usuário assim que você abrir a Home
  if current_user && current_user.email == "seu-email@exemplo.com"
    current_user.update(role: "prestador")
  end

  @services = Service.all
end
end
