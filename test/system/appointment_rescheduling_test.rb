# frozen_string_literal: true

require 'application_system_test_case'
require_relative '../support/rescheduling_setup'

class AppointmentReschedulingSystemTest < ApplicationSystemTestCase
  include ReschedulingSetup

  setup do
    @appointment = create_paid_appointment
  end

  # rubocop:disable-next Minitest/MultipleAssertions
  test 'client reschedules and reloads the persisted history' do
    login_as_participant(users(:two))
    visit appointment_path(@appointment)
    click_link 'Reagendar'

    assert_current_path edit_appointment_path(@appointment), wait: 10
    select '14:00', from: 'Novo horário'
    click_button 'Confirmar reagendamento'

    assert_current_path appointment_path(@appointment), wait: 10
    assert_text 'Agendamento reagendado com sucesso'
    visit appointment_path(@appointment)

    assert_text 'Histórico de reagendamentos'
    assert_text '14:00'
  end

  # rubocop:disable-next Minitest/MultipleAssertions
  test 'provider changes the date dynamically and reschedules' do
    skip 'Atualização dinâmica requer Selenium' if Capybara.current_driver == :rack_test
    login_as_participant(users(:one))
    visit provider_calendar_path
    find('.fc-next-button', wait: 10).click
    find('.fc-event', text: @appointment.service.nome).click
    click_link 'Ver detalhes do agendamento'
    click_link 'Reagendar'
    next_date = @appointment.start_time.to_date + 1.day
    execute_script("const input = document.querySelector('#appointment_date'); input.value = arguments[0]; " \
                   "input.dispatchEvent(new Event('change', { bubbles: true }));", next_date.iso8601)
    select '15:00', from: 'Novo horário'
    click_button 'Confirmar reagendamento'

    assert_current_path appointment_path(@appointment), wait: 10
    assert_text 'Agendamento reagendado com sucesso'
    visit appointment_path(@appointment)

    assert_text 'Histórico de reagendamentos'
    assert_equal next_date, @appointment.reload.start_time.to_date
  end

  test 'reports a newly occupied slot without losing the booking' do
    login_as_participant(users(:two))
    visit edit_appointment_path(@appointment)
    create_paid_appointment(hour: 14)
    select '14:00', from: 'Novo horário'
    click_button 'Confirmar reagendamento'

    assert_text 'O prestador já está atendendo outro cliente'
    assert_equal 10, @appointment.reload.start_time.hour
  end

  private

  def login_as_participant(user)
    visit new_user_session_path
    fill_in 'E-mail', with: user.email
    fill_in 'Senha', with: 'password123'
    click_button 'Entrar'

    assert_current_path root_path, wait: 10
    assert_selector 'h1', text: 'Meus Agendamentos'
  end
end
