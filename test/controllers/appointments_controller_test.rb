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

    assert_difference("@client.appointments.count", 1) do
      post service_appointments_url(@service), params: {
        appointment: {},
        appointment_date: appointment_date.iso8601,
        appointment_hour: "10:00"
      }
    end

    assert_redirected_to appointments_url
    assert_equal @client, Appointment.order(:created_at).last.client
  end

  test "shows an appointment belonging to the signed in client" do
    get appointment_url(@appointment)

    assert_response :success
  end

  test "updates an appointment status" do
    patch appointment_url(@appointment), params: {
      appointment: { status: "confirmado" }
    }

    assert_redirected_to appointments_url
    assert @appointment.reload.confirmado?
  end

  test "does not expose another users appointment" do
    other_appointment = appointments(:one)

    get appointment_url(other_appointment)

    assert_redirected_to root_url
  end
end
