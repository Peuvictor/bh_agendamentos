require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
  end

  test "should get index" do
    get dashboard_url
    assert_response :success
  end

  test "excludes refunded appointments from financial metrics" do
    Appointment.create!(
      client: users(:two),
      service: services(:one),
      start_time: 7.days.from_now.change(hour: 9, min: 0)
    )
    refunded_service = Service.create!(
      user: users(:one),
      nome: "Serviço reembolsado",
      descricao: "Não deve entrar nas métricas financeiras",
      duration: 30,
      preco: 777
    )
    Appointment.create!(
      client: users(:two),
      service: refunded_service,
      start_time: 8.days.from_now.change(hour: 9, min: 0),
      status: :reembolsado,
      refunded_at: Time.current
    )

    get dashboard_url

    assert_response :success
    assert_match(/R\$\s+9,99/, response.body)
    assert_no_match(/R\$ 786,99|777\.0/, response.body)
  end
end
