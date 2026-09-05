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

  # rubocop:disable-next Minitest/MultipleAssertions
  test "archives an owned service without changing historical counts" do
    historical_counts = [Appointment.count, Payment.count, Review.count]

    assert_no_difference(["Service.count", "Appointment.count", "Payment.count", "Review.count"]) do
      patch archive_service_url(@service)
    end

    assert_predicate @service.reload, :archived?
    assert_equal historical_counts, [Appointment.count, Payment.count, Review.count]
    assert_redirected_to services_url
  end

  test "reactivates a service archived by its provider" do
    @service.archive!

    patch reactivate_service_url(@service)

    assert_not_predicate @service.reload, :archived?
    assert_redirected_to services_url
  end

  test "does not edit an archived service" do
    @service.archive!

    get edit_service_url(@service)

    assert_redirected_to services_url

    patch service_url(@service), params: { service: { nome: "Nome manipulado" } }

    assert_redirected_to services_url
    assert_not_equal "Nome manipulado", @service.reload.nome
  end

  test "does not reactivate an administrative archive" do
    @service.archive!(by_admin: true)

    patch reactivate_service_url(@service)

    assert_predicate @service.reload, :archived?
    assert_predicate @service, :archived_by_admin?
    assert_redirected_to services_url
  end

  # rubocop:disable-next Minitest/MultipleAssertions
  test "lists active and archived services in separate sections" do
    @service.archive!

    get services_url

    assert_response :success
    assert_select "#active-services-heading", text: "Serviços ativos"
    assert_select "#archived-services-heading", text: "Serviços arquivados"
    assert_select "form[action='#{reactivate_service_path(@service)}']"
    assert_select "a[href='#{edit_service_path(@service)}']", count: 0
  end

  test "rejects a client" do
    sign_out @provider
    sign_in users(:two)

    get services_url

    assert_redirected_to root_url
  end
end
