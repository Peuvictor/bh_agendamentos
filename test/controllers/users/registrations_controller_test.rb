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

    test "rejects a short password submitted directly to registration" do
      params = registration_params(role: "client").merge(password: "Abc12!x", password_confirmation: "Abc12!x")

      assert_no_difference("User.count") do
        post user_registration_path, params: { user: params }
      end
      assert_response :unprocessable_entity
    end

    test "shows password requirements on registration" do
      get new_user_registration_path

      assert_select 'input[name="user[password]"][minlength="8"][required]'
      assert_select '#password-requirements', text: /pelo menos 8 caracteres/
      assert_select '#password-requirements', text: /maiúscula, letra minúscula, número e caractere especial/
    end

    test "rejects registration without the required password categories" do
      params = registration_params(role: "client").merge(password: "teste1234", password_confirmation: "teste1234")

      assert_no_difference("User.count") do
        post user_registration_path, params: { user: params }
      end
      assert_response :unprocessable_entity
    end

    test "rejects a replacement password without the required categories" do
      user = users(:one)
      sign_in user

      put user_registration_path, params: { user: { current_password: "password123", password: "teste1234",
                                                    password_confirmation: "teste1234" } }

      assert_response :unprocessable_entity
      assert user.reload.valid_password?("password123")
    end

    test "allows profile updates without replacing an existing password" do
      user = users(:one)
      sign_in user

      put user_registration_path, params: { user: { nome: "Nome atualizado", current_password: "password123",
                                                    password: "", password_confirmation: "" } }

      assert_redirected_to root_path
      assert_equal "Nome atualizado", user.reload.nome
      assert user.valid_password?("password123")
    end

    test "rejects a short replacement password" do
      user = users(:one)
      sign_in user

      put user_registration_path, params: { user: { current_password: "password123", password: "Abc12!x",
                                                    password_confirmation: "Abc12!x" } }

      assert_response :unprocessable_entity
      assert user.reload.valid_password?("password123")
    end

    test "allows replacing an existing password with eight characters and all required categories" do
      user = users(:one)
      sign_in user

      put user_registration_path, params: { user: { current_password: "password123", password: "Teste12!",
                                                    password_confirmation: "Teste12!" } }

      assert_redirected_to root_path
      assert user.reload.valid_password?("Teste12!")
    end

    private

    def registration_params(role:)
      {
        nome: "Usuário de Teste",
        email: "#{SecureRandom.hex(8)}@example.com",
        password: "Teste123!",
        password_confirmation: "Teste123!",
        role: role
      }
    end
  end
end
