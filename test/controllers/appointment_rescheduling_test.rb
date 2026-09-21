# frozen_string_literal: true

require 'test_helper'
require_relative '../support/rescheduling_setup'

# rubocop:disable Minitest/MultipleAssertions
class AppointmentReschedulingTest < ActionDispatch::IntegrationTest
  include ReschedulingSetup

  setup do
    @appointment = create_paid_appointment
    sign_in users(:two)
  end

  test 'shows the form and changes only scheduling attributes' do
    get edit_appointment_url(@appointment)

    assert_response :success
    assert_select 'input[name=schedule_token]'
    patch appointment_url(@appointment), params: form_params.merge(
      appointment: { status: 'cancelado', client_id: users(:one).id, service_id: services(:two).id }
    )

    assert_redirected_to appointment_url(@appointment)
    assert_equal 14, @appointment.reload.start_time.hour
    assert_predicate @appointment, :confirmado?
    assert_equal users(:two), @appointment.client
    assert_equal services(:one), @appointment.service
  end

  test 'provider can use the same form and endpoint' do
    sign_in users(:one)
    get edit_appointment_url(@appointment)

    assert_response :success
    patch appointment_url(@appointment), params: form_params

    assert_redirected_to appointment_url(@appointment)
    assert_equal users(:one), @appointment.reschedulings.sole.actor
  end

  test 'slots exclude the current booking and use its original duration' do
    @appointment.service.update!(duration: 120)
    get available_slots_appointment_url(@appointment), params: { date: @appointment.start_time.to_date.iso8601 }

    assert_response :success
    assert_includes response.parsed_body.fetch('slots'), '10:00'
    assert_includes response.parsed_body.fetch('slots'), '18:30'
  end

  test 'slots reject invalid dates and ineligible bookings' do
    get available_slots_appointment_url(@appointment), params: { date: 'invalid' }

    assert_response :unprocessable_content
    @appointment.update!(status: :cancelado)
    get available_slots_appointment_url(@appointment), params: { date: Date.tomorrow.iso8601 }

    assert_response :unprocessable_content
    assert_empty response.parsed_body.fetch('slots')
  end

  test 'unauthenticated and unrelated accounts cannot access rescheduling' do
    sign_out users(:two)
    get edit_appointment_url(@appointment)

    assert_redirected_to new_user_session_url
    sign_in User.create!(nome: 'Terceiro', email: 'third@example.com', password: 'Teste123!')
    get available_slots_appointment_url(@appointment), params: { date: Date.tomorrow.iso8601 }

    assert_redirected_to root_url
    patch appointment_url(@appointment), params: form_params

    assert_redirected_to root_url
    assert_empty @appointment.reschedulings
  end

  test 'conflicts keep the selected date and render a validation error' do
    patch appointment_url(@appointment), params: form_params.merge(appointment_hour: '07:00')

    assert_response :unprocessable_content
    assert_select '[role=alert]', text: /não está disponível/
    assert_select "input[name=appointment_date][value='#{@appointment.start_time.to_date.iso8601}']"
  end

  test 'a missing token cannot change a paid appointment' do
    patch appointment_url(@appointment), params: form_params.except(:schedule_token)

    assert_response :conflict
    assert_equal 10, @appointment.reload.start_time.hour
    assert_empty @appointment.reschedulings
  end

  test 'stale forms return conflict and require reloading' do
    params = form_params

    assert rescheduler(@appointment, hour: '15:00').call
    patch appointment_url(@appointment), params: params

    assert_response :conflict
    assert_select 'input[type=submit][disabled]'
    assert_select 'a', text: 'Recarregar formulário'
  end

  test 'history remains visible after cancellation and shows the amount paid' do
    assert rescheduler(@appointment).call
    @appointment.service.update!(preco: 200)
    get appointment_url(@appointment)

    assert_select 'span', text: /R\$ 9,99/
    @appointment.update!(status: :cancelado)
    get appointment_url(@appointment)

    assert_select 'h2', text: 'Histórico de reagendamentos'
    assert_select 'a', text: 'Reagendar', count: 0
  end

  test 'provider cannot revive a refunded or canceled booking through status update' do
    sign_in users(:one)
    %i[cancelado reembolsado].each do |status|
      @appointment.update!(status: status)
      patch update_status_appointment_url(@appointment), params: { status: 'confirmado' }

      assert_equal status.to_s, @appointment.reload.status
    end
  end

  private

  def form_params
    { appointment_date: @appointment.start_time.to_date.iso8601, appointment_hour: '14:00',
      schedule_token: @appointment.schedule_token }
  end
end

# rubocop:enable Minitest/MultipleAssertions
