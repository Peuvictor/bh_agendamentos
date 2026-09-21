# frozen_string_literal: true

require 'application_system_test_case'
require_relative '../support/mobile_browser_helpers'
require_relative '../support/rescheduling_setup'

# These scenarios check one user journey across several responsive states.
# rubocop:disable-next Minitest/MultipleAssertions, Metrics/ClassLength
class MobileLayoutTest < ApplicationSystemTestCase
  include MobileBrowserHelpers
  include ReschedulingSetup

  setup do
    skip 'Validação responsiva requer Selenium' if Capybara.current_driver == :rack_test
    mobile_viewport
    services(:one).update!(nome: "Atendimento personalizado #{'especializado' * 8}")
    users(:one).update!(nome: "Prestador #{'Sobrenome' * 8}")
  end

  teardown do
    page.driver.browser.execute_cdp('Emulation.clearDeviceMetricsOverride') unless Capybara.current_driver == :rack_test
  end

  test 'visitor pages fit and the menu supports keyboard and resizing' do
    inspect_mobile_pages([vitrine_path, new_user_session_path, new_user_registration_path, new_user_password_path,
                          edit_user_password_path(reset_password_token: 'invalid-test-token'),
                          service_reviews_path(services(:one))])
    mobile_viewport(320)
    visit new_user_registration_path
    select 'Quero oferecer meus serviços (Prestador)', from: 'user_role_select'

    assert_selector '#provider-extra-fields', visible: true
    assert_mobile_fit
    click_button 'Menu'
    capture_mobile('mobile-menu')

    assert_link 'Entrar'
    find_button('Menu').send_keys(:escape)

    assert_no_link 'Entrar', href: new_user_session_path, visible: true
    assert_selector '.navigation-toggle:focus'
    click_button 'Menu'
    mobile_viewport(1440)

    assert_no_button 'Menu', visible: true
    assert_link 'Entrar'
    mobile_viewport(320)

    assert_selector 'button[aria-expanded="false"]', text: 'Menu'
  end

  test 'client pages and rescheduling fit with persisted changes' do
    appointment = create_paid_appointment
    mobile_login(users(:two))
    inspect_mobile_pages([appointments_path, appointment_path(appointment), edit_appointment_path(appointment),
                          new_service_appointment_path(services(:one)), perfil_path, edit_user_registration_path])
    mobile_viewport(320)
    visit edit_appointment_path(appointment)
    select '14:00', from: 'Novo horário'
    click_button 'Confirmar reagendamento'

    assert_current_path appointment_path(appointment), wait: 10
    visit appointment_path(appointment)

    assert_text 'Histórico de reagendamentos'
    assert_equal 14, appointment.reload.start_time.hour
    assert_mobile_fit
    click_button 'Menu'

    assert_no_link 'Disponibilidade', exact: false
    click_button 'Sair'

    assert_link 'Entrar', visible: :all
  end

  # rubocop:disable-next Metrics/BlockLength
  test 'provider pages fit including calendar details and empty states' do
    block = users(:one).availability_blocks.create!(starts_at: 7.days.from_now.beginning_of_day,
                                                    ends_at: 8.days.from_now.beginning_of_day,
                                                    reason: "Motivo #{'indisponível' * 10}")
    mobile_login(users(:one))
    click_button 'Menu'

    assert_link '🕒 Disponibilidade'
    assert_no_link '👑 MODO DEUS'
    inspect_mobile_pages([services_path, new_service_path, edit_service_path(services(:one)),
                          service_path(services(:one)), dashboard_path, provider_availability_path,
                          edit_provider_availability_block_path(block), provider_calendar_path])
    mobile_viewport(320)
    visit provider_calendar_path

    assert_selector '.fc-timeGridDay-view'
    7.times { find('.fc-next-button').click }
    find('.fc-event', text: 'Bloqueio').click

    assert_selector 'dialog[open]', text: block.reason
    assert_no_link 'Ver detalhes do agendamento'
    assert_mobile_fit
    capture_mobile('mobile-calendar')
    find('button[aria-label="Fechar detalhes"]').click
    find('.fc-dayGridMonth-button').click

    assert_selector '.fc-dayGridMonth-view'
    title = find('.fc-toolbar-title').text
    mobile_viewport(1440)

    assert_selector '.fc-dayGridMonth-view'
    mobile_viewport(320)

    assert_selector '.fc-dayGridMonth-view'
    assert_equal title, find('.fc-toolbar-title').text
    assert_mobile_fit
  end

  test 'admin records become cards and keep service actions' do
    admin = User.create!(nome: 'Administrador', email: 'admin-mobile@example.com', password: 'Teste123!',
                         role: :admin)
    create_paid_appointment
    mobile_login(admin, password: 'Teste123!')
    click_button 'Menu'

    assert_link '👑 MODO DEUS'
    assert_no_link '🕒 Disponibilidade'
    inspect_mobile_pages([admin_root_path, admin_users_path, admin_services_path])
    mobile_viewport(320)
    visit admin_services_path

    assert_equal 'block', find('.responsive-records tbody tr', match: :first).style('display')['display']
    capture_mobile('mobile-admin')
    within(find('.responsive-records tbody tr', text: services(:one).nome)) { click_button 'Arquivar' }

    assert_text 'Arquivado pela administração'
    visit admin_services_path
    within(find('.responsive-records tbody tr', text: services(:one).nome)) { click_button 'Reativar' }

    assert_text 'Ativo'
    assert_not services(:one).reload.archived?
    mobile_viewport(1440)

    assert_equal 'table-row', find('.responsive-records tbody tr', match: :first).style('display')['display']
  end
end
