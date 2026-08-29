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

  # rubocop:disable-next Minitest/MultipleAssertions
  test 'shows a refund before historical expiration details and hides payment actions' do
    client = users(:two)
    appointment = Appointment.create!(
      client: client,
      service: services(:one),
      start_time: 10.days.from_now.change(hour: 14, min: 0),
      expired_at: 2.minutes.ago,
      refunded_at: Time.current,
      status: :reembolsado
    )
    sign_in client

    get appointment_url(appointment)

    assert_response :success
    assert_includes response.body, 'Pagamento reembolsado'
    assert_no_match 'Expirado por falta de pagamento', response.body
    assert_no_match 'paymentBrick_container', response.body
  end
end
