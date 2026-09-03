require "test_helper"

# rubocop:disable-next Metrics/ClassLength
class AppointmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client = users(:two)
    @service = services(:one)
    @appointment = appointments(:two)
    sign_in @client
  end

  test "lists the signed in client appointments" do
    get appointments_url

    assert_response :success
  end

  test "lists appointments booked by a provider instead of appointments received by them" do
    provider = users(:one)
    other_provider = create_other_provider
    booked_service = other_provider.services.create!(
      nome: "Serviço reservado pelo prestador",
      descricao: "Usado para distinguir reservas feitas e recebidas",
      duration: 30,
      preco: 50
    )
    booked_appointment = Appointment.create!(
      client: provider,
      service: booked_service,
      start_time: 7.days.from_now.change(hour: 10, min: 0)
    )
    received_appointment = Appointment.create!(
      client: @client,
      service: @service,
      start_time: 7.days.from_now.change(hour: 11, min: 0)
    )
    sign_out @client
    sign_in provider

    get appointments_url

    assert_response :success
    assert_select "a[href='#{appointment_path(booked_appointment)}']", text: "Ver detalhes"
    assert_select "a[href='#{appointment_path(received_appointment)}']", count: 0
  end

  test "renders the nested appointment form" do
    get new_service_appointment_url(@service)

    assert_response :success
  end

  test "creates an appointment for the signed in client" do
    appointment_date = 2.days.from_now.to_date

    assert_no_enqueued_emails do
      assert_difference("@client.appointments.count", 1) do
        post service_appointments_url(@service), params: {
          appointment: {},
          appointment_date: appointment_date.iso8601,
          appointment_hour: "10:00"
        }
      end
    end

    appointment = Appointment.order(:created_at).last

    assert_redirected_to appointment_url(appointment)
    assert_equal @client, appointment.client
    assert appointment.pendente?
    assert_in_delta 30.minutes.from_now, appointment.expires_at, 5.seconds
  end

  test "shows an appointment belonging to the signed in client" do
    get appointment_url(@appointment)

    assert_response :success
    assert_no_match "paymentBrick_container", response.body
  end

  test "renders the configured Mercado Pago checkout for a pending appointment" do
    appointment = Appointment.create!(
      client: @client,
      service: @service,
      start_time: 6.days.from_now.change(hour: 14, min: 0)
    )
    previous_public_key = ENV["MERCADO_PAGO_PUBLIC_KEY"]
    ENV["MERCADO_PAGO_PUBLIC_KEY"] = "TEST-public-key"

    get appointment_url(appointment)

    assert_response :success
    assert_select "meta[name='mp-public-key'][content='TEST-public-key']"
    assert_select "[data-controller='payment']"
    assert_select "[data-payment-target='feedback']"
    assert_select "#paymentBrick_container"
  ensure
    ENV["MERCADO_PAGO_PUBLIC_KEY"] = previous_public_key
  end

  test "does not let a client confirm an appointment through the update route" do
    patch appointment_url(@appointment), params: {
      appointment: { status: "confirmado" }
    }

    assert_redirected_to appointment_url(@appointment)
    assert_not @appointment.reload.confirmado?
  end

  test "does not expose another users appointment" do
    other_appointment = appointments(:one)

    get appointment_url(other_appointment)

    assert_redirected_to root_url
  end

  test "cancels a future appointment without deleting its history" do
    appointment = Appointment.create!(
      client: @client,
      service: @service,
      start_time: 4.days.from_now.change(hour: 14, min: 0)
    )

    assert_no_difference("Appointment.count") do
      assert_enqueued_emails 1 do
        delete appointment_url(appointment)
      end
    end

    assert appointment.reload.cancelado?
    assert_redirected_to appointments_url
  end

  test "does not let the provider confirm an unpaid appointment" do
    appointment = Appointment.create!(
      client: @client,
      service: @service,
      start_time: 5.days.from_now.change(hour: 14, min: 0)
    )
    sign_out @client
    sign_in @service.user

    assert_no_enqueued_emails do
      patch update_status_appointment_url(appointment, status: :confirmado)
    end

    assert appointment.reload.pendente?
    assert_redirected_to dashboard_url
  end

  test "does not let the provider assign the refunded state manually" do
    appointment = Appointment.create!(
      client: @client,
      service: @service,
      start_time: 5.days.from_now.change(hour: 14, min: 0)
    )
    sign_out @client
    sign_in @service.user

    assert_no_enqueued_emails do
      patch update_status_appointment_url(appointment, status: :reembolsado)
    end

    assert_predicate appointment.reload, :pendente?
    assert_redirected_to dashboard_url
  end

  test "does not downgrade a refunded appointment through cancellation" do
    appointment = Appointment.create!(
      client: @client,
      service: @service,
      start_time: 5.days.from_now.change(hour: 15, min: 0),
      status: :reembolsado,
      refunded_at: Time.current
    )

    assert_no_enqueued_emails do
      delete appointment_url(appointment)
    end

    assert_predicate appointment.reload, :reembolsado?
    assert_redirected_to appointments_url
  end

  private

  def create_other_provider
    User.create!(
      nome: "Outro prestador",
      email: "outro-prestador@example.com",
      password: "password123",
      role: :provider,
      bairro: "Savassi"
    )
  end
end
