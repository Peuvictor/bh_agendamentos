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

  # rubocop:disable-next Minitest/MultipleAssertions
  test "archives a service administratively without deleting it" do
    service = services(:one)

    assert_no_difference(["Service.count", "Appointment.count", "Payment.count", "Review.count"]) do
      patch archive_admin_service_url(service)
    end

    assert_predicate service.reload, :archived?
    assert_predicate service, :archived_by_admin?
    assert_redirected_to admin_services_url
  end

  test "administrative archive takes precedence over a provider archive" do
    service = services(:one)
    service.archive!

    patch archive_admin_service_url(service)

    assert_predicate service.reload, :archived_by_admin?
  end

  test "reactivates any archived service" do
    service = services(:one)
    service.archive!(by_admin: true)

    patch reactivate_admin_service_url(service)

    assert_not_predicate service.reload, :archived?
    assert_not service.archived_by_admin?
  end

  test "shows the status and archive controls" do
    services(:one).archive!(by_admin: true)

    get admin_services_url

    assert_select "span", text: "Arquivado pela administração"
    assert_select "form[action='#{reactivate_admin_service_path(services(:one))}']"
    assert_no_match(/Deletar|Banir/i, response.body)
  end
end
