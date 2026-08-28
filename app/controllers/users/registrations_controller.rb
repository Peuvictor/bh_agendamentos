module Users
  class RegistrationsController < Devise::RegistrationsController
    protected

    def sign_up_params
      super.merge(role: public_role)
    end

    private

    # Administradores nunca podem ser criados pelo cadastro público.
    # Valores ausentes, desconhecidos ou manipulados viram uma conta de cliente.
    def public_role
      params.dig(:user, :role) == "provider" ? "provider" : "client"
    end
  end
end
