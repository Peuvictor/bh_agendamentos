class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  # 👇 O REDIRECIONAMENTO ENTRA AQUI
  def after_sign_in_path_for(resource)
    # Se o usuário for admin, enviamos para Agendamentos, senão, segue o fluxo padrão
    if resource.admin?
      appointments_path
    else
      root_path
    end
  end

  def configure_permitted_parameters
    # 1. CADASTRO INICIAL:
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
