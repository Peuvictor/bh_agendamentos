class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  # Redirecionamento estratégico após o login
  def after_sign_in_path_for(resource)
    if resource.admin?
      appointments_path
    else
      root_path
    end
  end

  def configure_permitted_parameters
    # 1. CADASTRO INICIAL:
    # Adicionamos :bairro para que o usuário possa escolher onde mora/trabalha já no registro
    devise_parameter_sanitizer.permit(:sign_up, keys: [:nome, :telefone, :role, :bairro])

    # 2. EDIÇÃO DE PERFIL:
    # Adicionamos :bairro aqui para permitir que o prestador atualize sua região de atendimento
    devise_parameter_sanitizer.permit(:account_update, keys: [:nome, :telefone, :bio, :endereco, :avatar, :bairro])
  end

  # Trava de segurança para o Modo Deus
  def authorize_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "Acesso Negado: Área restrita para administradores do sistema."
    end
  end
end
