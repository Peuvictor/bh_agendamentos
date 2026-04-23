class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin!

  def index
    # Busca todos os usuários, ordenados por nome
    @users = User.all.order(:nome)
  end

  def destroy
    @user = User.find(params[:id])

    # Trava de segurança: impede o admin de se auto-excluir
    if @user == current_user
      redirect_to admin_users_path, alert: "Você não pode excluir sua própria conta de administrador, uai!"
      return
    end

    @user.destroy
    redirect_to admin_users_path, notice: "Usuário removido com sucesso da plataforma."
  end
end
