class ApplicationController < ActionController::Base
  # Diz pro Rails rodar esse método antes de qualquer ação do Devise
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    # Libera os campos na hora de atualizar a conta (account_update)
    devise_parameter_sanitizer.permit(:account_update, keys: [:nome, :telefone, :bio, :endereco, :avatar])

    # Bônus: Se quiser que eles já preencham o nome na hora de criar a conta (sign_up)
    devise_parameter_sanitizer.permit(:sign_up, keys: [:nome])
  end
end
