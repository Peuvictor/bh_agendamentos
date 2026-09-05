require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_response :success
  end

  test "does not list archived services in the storefront" do
    archived_service = services(:one)
    archived_service.update!(nome: "Serviço oculto")
    archived_service.archive!

    get vitrine_url

    assert_response :success
    assert_select "a[href='#{new_service_appointment_path(archived_service)}']", count: 0
    assert_select "a[href='#{new_service_appointment_path(services(:two))}']", count: 1
  end

  test "does not return archived services in search results" do
    archived_service = services(:one)
    archived_service.update!(nome: "Serviço Arquivado Exclusivo")
    archived_service.archive!

    get vitrine_url, params: { query: "Arquivado Exclusivo" }

    assert_response :success
    assert_select "h3", text: "Serviço Arquivado Exclusivo", count: 0
    assert_select "h3", text: "Nenhum serviço encontrado"
  end
end
