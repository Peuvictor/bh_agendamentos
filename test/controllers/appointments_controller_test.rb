require "test_helper"

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
  end

  test "shows an appointment belonging to the signed in client" do
    get appointment_url(@appointment)

    assert_response :success
    assert_no_match "paymentBrick_container", response.body
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
end
