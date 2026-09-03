require "test_helper"

class ServicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @provider = users(:one)
    @service = services(:one)
    sign_in @provider
  end

  test "lists only the signed in provider services" do
    get services_url

    assert_response :success
  end

  test "renders the new service form" do
    get new_service_url

    assert_response :success
    required_fields = "input[name='service[nome]'][required], " \
                      "input[name='service[duration]'][required], " \
                      "input[name='service[preco]'][required]"

    assert_select required_fields, count: 3
  end

  test "shows validation errors when required service data is missing" do
    assert_no_difference("Service.count") do
      post services_url, params: { service: { nome: "", duration: "", preco: "" } }
    end

    assert_response :unprocessable_content
    assert_select "[role='alert']", text: /campos que precisam ser corrigidos/
  end

  test "creates a service owned by the signed in provider" do
    assert_difference("@provider.services.count", 1) do
      post services_url, params: {
        service: {
          nome: "Novo serviço",
          descricao: "Descrição do novo serviço",
          duration: 60,
          preco: 80
        }
      }
    end

    assert_redirected_to services_url
  end

  test "shows a service owned by the signed in provider" do
    get service_url(@service)

    assert_response :success
  end

  test "renders the edit form for an owned service" do
    get edit_service_url(@service)

    assert_response :success
  end

  test "updates an owned service" do
    patch service_url(@service), params: {
      service: { nome: "Serviço atualizado", duration: 45, preco: 120 }
    }

    assert_redirected_to services_url
    assert_equal "Serviço atualizado", @service.reload.nome
  end

  test "destroys an owned service without appointments" do
    service = @provider.services.create!(
      nome: "Serviço descartável",
      descricao: "Criado para o teste de exclusão",
      duration: 30,
      preco: 50
    )

    assert_difference("Service.count", -1) do
      delete service_url(service)
    end

    assert_redirected_to services_url
  end

  test "rejects a client" do
    sign_out @provider
    sign_in users(:two)

    get services_url

    assert_redirected_to root_url
  end
end
