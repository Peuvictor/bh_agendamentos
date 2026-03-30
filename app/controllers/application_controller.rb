class ApplicationController < ActionController::Base
  # Adicione estas linhas abaixo
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:nome, :role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:nome, :role])
  end
end
