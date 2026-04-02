class ProfilesController < ApplicationController
  # Trava de segurança: só entra se estiver logado
  before_action :authenticate_user!

  def show
    # Pega o usuário que está logado agora para mostrar na tela
    @user = current_user
  end
end
