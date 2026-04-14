class ApplicationController < ActionController::Base
  # Diz pro Rails rodar esse método antes de qualquer ação do Devise
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    # 1. CADASTRO INICIAL (Cliente Padrão):
    # Libera apenas o básico. Ninguém consegue enviar 'role' ou 'bio' pela porta da frente.
    devise_parameter_sanitizer.permit(:sign_up, keys: [:nome, :telefone])

    # 2. EDIÇÃO DE PERFIL:
    # Libera todos os campos. (A view já protege para que só o Prestador veja os campos de bio/foto/endereço).
    devise_parameter_sanitizer.permit(:account_update, keys: [:nome, :telefone, :bio, :endereco, :avatar])
  end

  def authorize_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "Acesso Negado: Área restrita para administradores do sistema."
    end
  end
end
