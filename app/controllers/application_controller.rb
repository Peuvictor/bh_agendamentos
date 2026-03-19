class ApplicationController < ActionController::Base
  # Adicione estas linhas abaixo
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    # Permite o campo 'nome' no cadastro (sign_up)
    devise_parameter_sanitizer.permit(:sign_up, keys: [:nome])
    # Permite o campo 'nome' na edição de conta (account_update)
    devise_parameter_sanitizer.permit(:account_update, keys: [:nome])
  end
end
