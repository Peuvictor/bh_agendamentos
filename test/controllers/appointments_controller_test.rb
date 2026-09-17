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

  test "does not let a provider open the appointment form" do
    provider = users(:one)
    sign_out @client
    sign_in provider

    get new_service_appointment_url(@service)

    assert_redirected_to vitrine_url
    assert_equal "Apenas clientes podem agendar serviços.", flash[:alert]
  end

  test "does not let a provider create an appointment directly" do
    sign_out @client
    sign_in users(:one)

    assert_no_difference("Appointment.count") do
      post service_appointments_url(@service), params: {
        appointment: {},
        appointment_date: 3.days.from_now.to_date.iso8601,
        appointment_hour: "10:00"
      }
    end

    assert_redirected_to vitrine_url
    assert_equal "Apenas clientes podem agendar serviços.", flash[:alert]
  end

  test "does not expose available slots to a provider booking request" do
    sign_out @client
    sign_in users(:one)

    get available_slots_service_url(@service, date: 3.days.from_now.to_date.iso8601), as: :json

    assert_response :forbidden
    assert_equal "Apenas clientes podem agendar serviços.", response.parsed_body.fetch("error")
  end

  test "renders the nested appointment form" do
    get new_service_appointment_url(@service)

    assert_response :success
  end

  test "redirects the form for an archived service to the storefront" do
    @service.archive!

    get new_service_appointment_url(@service)

    assert_redirected_to vitrine_url
    assert_equal "Este serviço está arquivado e não aceita novas reservas.", flash[:alert]
  end

  test "redirects available slots for an archived service to the storefront" do
    @service.archive!

    get available_slots_service_url(@service, date: 3.days.from_now.to_date.iso8601), as: :json

    assert_redirected_to vitrine_url
  end

  test "rejects direct creation for an archived service" do
    @service.archive!

    assert_no_difference("Appointment.count") do
      post service_appointments_url(@service), params: {
        appointment: {},
        appointment_date: 3.days.from_now.to_date.iso8601,
        appointment_hour: "10:00"
      }
    end

    assert_redirected_to vitrine_url
  end

  test "returns only available slots for a selected date" do
    date = 3.days.from_now.to_date
    @service.user.availability_blocks.create!(
      service: @service,
      starts_at: Time.zone.local(date.year, date.month, date.day, 9),
      ends_at: Time.zone.local(date.year, date.month, date.day, 10)
    )

    get available_slots_service_url(@service, date: date.iso8601), as: :json

    assert_response :success
    slots = response.parsed_body.fetch("slots")

    assert_includes slots, "08:00"
    assert_not_includes slots, "09:00"
    assert_includes slots, "10:00"
  end

  test "rejects an appointment outside the providers working periods" do
    date = 4.days.from_now.to_date
    @service.user.availability_periods.where(weekday: date.wday).delete_all

    assert_no_difference("Appointment.count") do
      post service_appointments_url(@service), params: {
        appointment: {},
        appointment_date: date.iso8601,
        appointment_hour: "10:00"
      }
    end

    assert_response :unprocessable_content
    assert_select "li", text: /não está disponível na agenda do prestador/
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

  test "keeps a preexisting appointment visible after its service is archived" do
    appointment = Appointment.create!(
      client: @client,
      service: @service,
      start_time: 6.days.from_now.change(hour: 14, min: 0)
    )
    @service.archive!

    get appointments_url

    assert_response :success
    assert_select "a[href='#{appointment_path(appointment)}']", text: "Ver detalhes"
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
end
