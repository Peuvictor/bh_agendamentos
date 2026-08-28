require "test_helper"

module Users
  class RegistrationsControllerTest < ActionDispatch::IntegrationTest
    test "allows a client account through public registration" do
      assert_difference("User.count", 1) do
        post user_registration_path, params: { user: registration_params(role: "client") }
      end

      assert User.order(:created_at).last.client?
    end

    test "allows a provider account through public registration" do
      assert_difference("User.count", 1) do
        post user_registration_path, params: { user: registration_params(role: "provider") }
      end

      assert User.order(:created_at).last.provider?
    end

    test "does not allow an admin account through public registration" do
      assert_difference("User.count", 1) do
        post user_registration_path, params: { user: registration_params(role: "admin") }
      end

      assert User.order(:created_at).last.client?
    end

    test "uses the client role when the submitted role is unknown" do
      assert_difference("User.count", 1) do
        post user_registration_path, params: { user: registration_params(role: "super_admin") }
      end

      assert User.order(:created_at).last.client?
    end

    private

    def registration_params(role:)
      {
        nome: "Usuário de Teste",
        email: "#{SecureRandom.hex(8)}@example.com",
        password: "password123",
        password_confirmation: "password123",
        role: role
      }
    end
  end
end
