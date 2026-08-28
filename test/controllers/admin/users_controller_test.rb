require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      nome: "Admin de Teste",
      email: "admin-users@example.com",
      password: "password123",
      role: :admin
    )
    sign_in @admin
  end

  test "lists users for an admin" do
    get admin_users_url

    assert_response :success
  end

  test "destroys another user" do
    user = User.create!(
      nome: "Usuário removível",
      email: "removivel@example.com",
      password: "password123",
      role: :client
    )

    assert_difference("User.count", -1) do
      delete admin_user_url(user)
    end

    assert_redirected_to admin_users_url
  end

  test "does not allow an admin to delete itself" do
    assert_no_difference("User.count") do
      delete admin_user_url(@admin)
    end

    assert_redirected_to admin_users_url
  end
end
