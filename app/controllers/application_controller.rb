class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    # 1. CADASTRO INICIAL:
    # 👇 A MÁGICA ESTÁ AQUI: Adicionamos o :role nesta lista! 👇
    devise_parameter_sanitizer.permit(:sign_up, keys: [:nome, :telefone, :role])

    # 2. EDIÇÃO DE PERFIL:
    devise_parameter_sanitizer.permit(:account_update, keys: [:nome, :telefone, :bio, :endereco, :avatar])
  end

  def authorize_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "Acesso Negado: Área restrita para administradores do sistema."
    end
  end
end
