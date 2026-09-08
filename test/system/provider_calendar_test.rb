# frozen_string_literal: true

require 'application_system_test_case'

class ProviderCalendarTest < ApplicationSystemTestCase
  setup do
    @provider = users(:one)
    @client = users(:two)
    @service = services(:one)
  end

  # rubocop:disable-next Metrics/BlockLength, Minitest/MultipleAssertions
  test 'provider explores calendar events and optional history' do
    active_time = future_time(hour: 10)
    active = Appointment.create!(
      client: @client,
      service: @service,
      start_time: active_time,
      status: :confirmado
    )
    cancelled_service = @provider.services.create!(
      nome: 'Serviço cancelado no calendário',
      descricao: 'Permite distinguir o histórico na interface',
      duration: 30,
      preco: 40
    )
    cancelled = Appointment.create!(
      client: @client,
      service: cancelled_service,
      start_time: active_time + 1.hour,
      status: :cancelado
    )

    sign_in
    visit provider_calendar_path

    assert_text 'Calendário'
    assert_selector "[data-controller='provider-calendar']"
    assert_text 'Exibir cancelados e reembolsados'
    return if Capybara.current_driver == :rack_test

    assert_selector '.fc-timeGridWeek-view'
    find('.fc-next-button').click

    assert_text active.service.nome
    assert_no_text cancelled.service.nome

    find('.fc-event', text: active.client.nome).click

    assert_selector 'dialog[open]'
    assert_text active.client.nome
    assert_link 'Ver detalhes do agendamento', href: appointment_path(active)
    find('button[aria-label="Fechar detalhes"]').click

    check 'Exibir cancelados e reembolsados'

    assert_text cancelled.service.nome

    find('.fc-dayGridMonth-button').click

    assert_selector '.fc-dayGridMonth-view'
    find('.fc-timeGridDay-button').click

    assert_selector '.fc-timeGridDay-view'
  end

  private

  def sign_in
    visit new_user_session_path
    fill_in 'E-mail', with: @provider.email
    fill_in 'Senha', with: 'password123'
    click_button 'Entrar'
  end

  def future_time(hour:)
    date = 7.days.from_now.to_date
    Time.zone.local(date.year, date.month, date.day, hour)
  end
end
