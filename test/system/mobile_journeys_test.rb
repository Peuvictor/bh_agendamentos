# frozen_string_literal: true

require 'application_system_test_case'
require_relative '../support/mobile_browser_helpers'
require_relative '../support/rescheduling_setup'

# rubocop:disable-next Minitest/MultipleAssertions, Metrics/BlockLength
class MobileJourneysTest < ApplicationSystemTestCase
  include MobileBrowserHelpers
  include ReschedulingSetup

  setup do
    skip 'Interações mobile requerem Selenium' if Capybara.current_driver == :rack_test
    mobile_viewport(320)
  end

  teardown do
    page.driver.browser.execute_cdp('Emulation.clearDeviceMetricsOverride') unless Capybara.current_driver == :rack_test
  end

  test 'provider creates a service and edits the account on mobile' do
    mobile_login(users(:one))
    click_button 'Menu'
    click_link '✂️ Serviços'
    click_link '+ Novo Serviço'
    fill_in 'Nome do Serviço', with: 'AB'
    page.execute_script("document.querySelector('#service_nome').removeAttribute('minlength')")
    fill_in 'Descrição', with: 'Descrição do serviço no celular'
    fill_in 'Duração do Serviço', with: 45
    fill_in 'Preço do Serviço', with: 80

    click_button 'Salvar Serviço'

    assert_selector '[role=alert]'
    assert_mobile_fit
    fill_in 'Nome do Serviço', with: 'Atendimento mobile'
    click_button 'Salvar Serviço'

    assert_text 'Serviço criado com sucesso'
    assert_equal 45, users(:one).services.find_by!(nome: 'Atendimento mobile').duration
    click_button 'Menu'
    click_link 'Configurações'
    fill_in 'Nome Completo', with: 'Prestador Mobile'
    fill_in 'Senha Atual (obrigatória para salvar as mudanças)', with: 'password123'
    click_button 'Salvar Alterações'

    assert_current_path root_path, wait: 10
    visit edit_user_registration_path

    assert_field 'Nome Completo', with: 'Prestador Mobile'
    assert_mobile_fit
  end

  test 'provider adds and removes turns and persists a partial block' do
    mobile_login(users(:one))
    visit provider_availability_path
    within('.schedule-day', text: 'Segunda-feira') do
      set_native_field('Fim do turno 1 de Segunda-feira', '10:00')
      set_native_field('Início do turno 2 de Segunda-feira', '11:00')
      set_native_field('Fim do turno 2 de Segunda-feira', '12:00')
      click_button '+ Adicionar turno'
      set_native_field('Início do turno 3 de Segunda-feira', '13:00')
      set_native_field('Fim do turno 3 de Segunda-feira', '14:00')
      all('.schedule-period')[1].click_button 'Remover'

      assert_field 'Início do turno 2 de Segunda-feira', with: '13:00'
    end
    click_button 'Salvar horários semanais'

    assert_text 'Horários semanais atualizados'
    visit provider_availability_path

    assert_field 'Fim do turno 1 de Segunda-feira', with: '10:00'
    assert_field 'Início do turno 2 de Segunda-feira', with: '13:00'
    capture_mobile('mobile-turns')
    set_native_field('Data', 7.days.from_now.to_date.iso8601)
    uncheck 'Dia inteiro'
    set_native_field('De', '15:00')
    set_native_field('Até', '16:00')
    fill_in 'Motivo (opcional)', with: 'Compromisso mobile'
    click_button 'Adicionar bloqueio'

    assert_text 'Bloqueio adicionado'
    block = users(:one).availability_blocks.find_by!(reason: 'Compromisso mobile')
    click_link 'Editar', href: edit_provider_availability_block_path(block)
    set_native_field('Até', '17:00')
    click_button 'Salvar alterações'

    assert_text 'Bloqueio atualizado'
    assert_equal 17, block.reload.ends_at.hour
    assert_mobile_fit
  end

  test 'client submits a rating using keyboard on a small screen' do
    appointment = create_paid_appointment
    travel_to appointment.end_time + 1.hour do
      mobile_login(users(:two))
      visit appointments_path
      find_button('3 estrelas').send_keys(:enter)

      assert_selector 'button[aria-label="3 estrelas"][aria-pressed="true"]'
      assert_mobile_fit
      capture_mobile('mobile-rating')
      click_button 'Enviar Avaliação'

      assert_text 'Obrigado pela sua avaliação'
      visit appointments_path

      assert_text(/Sua Avaliação/i)
      assert_equal 3, appointment.reload.review.rating
    end
  end
end
