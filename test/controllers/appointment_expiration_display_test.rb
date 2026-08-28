# frozen_string_literal: true

require 'test_helper'

class AppointmentExpirationDisplayTest < ActionDispatch::IntegrationTest
  test 'shows payment expiration as distinct from manual cancellation' do
    client = users(:two)
    appointment = Appointment.create!(
      client: client,
      service: services(:one),
      start_time: 9.days.from_now.change(hour: 14, min: 0),
      expired_at: Time.current,
      status: :cancelado
    )
    sign_in client

    get appointment_url(appointment)

    assert_response :success
    assert_includes response.body, 'Expirado por falta de pagamento'
  end
end
