require "test_helper"

class Admin::ServicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      nome: "Admin de Teste",
      email: "admin-services@example.com",
      password: "password123",
      role: :admin
    )
    sign_in @admin
  end

  test "lists services for an admin" do
    get admin_services_url

    assert_response :success
  end

  test "destroys a service without appointments" do
    service = users(:one).services.create!(
      nome: "Serviço para moderação",
      duration: 30,
      preco: 40
    )

    assert_difference("Service.count", -1) do
      delete admin_service_url(service)
    end

    assert_redirected_to admin_services_url
  end
end
