# frozen_string_literal: true

require 'test_helper'

class AppointmentBookingAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @service = services(:one)
    @date = 5.days.from_now.to_date.iso8601
  end

  # Apply the complete authorization matrix independently to both restricted roles.
  # rubocop:disable-next Metrics/BlockLength
  %i[provider admin].each do |role|
    test "#{role} cannot open the booking form for another providers service" do
      sign_in restricted_user(role)

      get new_service_appointment_url(@service)

      assert_redirected_to vitrine_url
      assert_equal 'Apenas clientes podem agendar serviços.', flash[:alert]
    end

    test "#{role} cannot fetch new booking slots" do
      sign_in restricted_user(role)

      get available_slots_service_url(@service), params: { date: @date }, as: :json

      assert_response :forbidden
      assert_equal({ 'error' => 'Apenas clientes podem agendar serviços.' }, response.parsed_body)
    end

    test "#{role} cannot book on behalf of a client through HTML" do
      sign_in restricted_user(role)

      assert_no_difference('Appointment.count') do
        post service_appointments_url(@service), params: booking_params(users(:two))
      end

      assert_redirected_to vitrine_url
    end

    test "#{role} cannot book on behalf of a client through JSON" do
      sign_in restricted_user(role)

      assert_no_difference('Appointment.count') do
        post service_appointments_url(@service), params: booking_params(users(:two)), as: :json
      end

      assert_response :forbidden
      assert_equal 'Apenas clientes podem agendar serviços.', response.parsed_body.fetch('error')
    end

    test "#{role} cannot book through a Turbo form submission" do
      sign_in restricted_user(role)

      assert_no_difference('Appointment.count') do
        post service_appointments_url(@service), params: booking_params(users(:two)),
                                                 headers: { 'Accept' => 'text/vnd.turbo-stream.html, text/html' }
      end

      assert_redirected_to vitrine_url
    end

    test "#{role} sees the storefront without booking links" do
      sign_in restricted_user(role)

      get vitrine_url

      assert_response :success
      assert_select 'a', text: 'Agendar', count: 0
      assert_select 'span', text: 'Exclusivo para clientes'
    end
  end

  test 'visitors must sign in before opening a booking form' do
    get new_service_appointment_url(@service)

    assert_redirected_to new_user_session_url
  end

  test 'visitors cannot create bookings by sending a client id' do
    assert_no_difference('Appointment.count') do
      post service_appointments_url(@service), params: booking_params(users(:two))
    end

    assert_redirected_to new_user_session_url
  end

  test 'a client cannot assign a new booking to a provider using forged parameters' do
    sign_in users(:two)

    assert_difference('Appointment.count', 1) do
      post service_appointments_url(@service), params: booking_params(users(:one))
    end

    appointment = Appointment.order(:created_at).last

    assert_redirected_to appointment_url(appointment)
    assert_equal users(:two), appointment.client
  end

  private

  def restricted_user(role)
    User.create!(nome: 'Conta sem permissão de reserva', email: "#{role}-booking@example.com",
                 password: 'password123', role: role)
  end

  def booking_params(client)
    { appointment_date: @date, appointment_hour: '10:00', client_id: client.id,
      appointment: { client_id: client.id, role: 'client' } }
  end
end
