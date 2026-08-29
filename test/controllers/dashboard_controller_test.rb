require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
  end

  test "should get index" do
    get dashboard_url
    assert_response :success
  end

  test "uses approved payment amounts for received revenue and average ticket" do
    appointment = create_appointment(
      service: services(:one),
      start_time: 5.days.from_now.change(hour: 9),
      status: :confirmado
    )
    create_payment(appointment: appointment, amount: 49.90, status: :aprovado)
    services(:one).update!(preco: 999.90)

    get dashboard_url

    assert_select "h3", text: /R\$\s+49,90/
    assert_no_match(/R\$\s+999,90/, response.body)
  end

  test "renders consolidated revenue and customer cards" do
    get dashboard_url

    assert_select "p", text: "Receita Recebida"
    assert_select "p", text: "Ticket Médio"
    assert_select "p", text: "Clientes Pagantes"
  end

  test "forecasts only active future pending appointments" do
    active_service = create_service(nome: "Reserva ativa", preco: 35)
    active_appointment = create_appointment(
      service: active_service,
      start_time: 5.days.from_now.change(hour: 9)
    )
    create_payment(appointment: active_appointment, amount: 32, status: :pendente)

    expired_service = create_service(nome: "Reserva vencida", preco: 700)
    create_appointment(
      service: expired_service,
      start_time: 6.days.from_now.change(hour: 9),
      expires_at: 1.minute.ago
    )

    get dashboard_url

    assert_select "p", text: "Receita Prevista"
    assert_select "h3", text: /R\$\s+32,00/
    assert_no_match(/R\$\s+700,00/, response.body)
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

  private

  def create_service(nome:, preco:)
    Service.create!(
      user: users(:one),
      nome: nome,
      descricao: "Serviço usado no teste do dashboard",
      duration: 30,
      preco: preco
    )
  end

  def create_appointment(service:, start_time:, status: :pendente, expires_at: nil)
    attributes = {
      client: users(:two),
      service: service,
      start_time: start_time,
      status: status
    }
    attributes[:expires_at] = expires_at if expires_at

    Appointment.create!(**attributes)
  end

  def create_payment(appointment:, amount:, status:)
    Payment.create!(
      appointment: appointment,
      amount: amount,
      status: status,
      mp_transaction_id: "dashboard-#{SecureRandom.uuid}",
      idempotency_key: "dashboard-#{SecureRandom.uuid}"
    )
  end
end
