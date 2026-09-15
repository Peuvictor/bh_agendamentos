# frozen_string_literal: true

require 'application_system_test_case'
require_relative '../support/demo_seed_helpers'

class DemoJourneysTest < ApplicationSystemTestCase
  include DemoSeedHelpers

  if ENV['SYSTEM_TEST_DRIVER'] == 'selenium'
    # The demo loads full-size photos. Wait for their decoding explicitly below
    # instead of blocking navigation on every page resource.
    client = Selenium::WebDriver::Remote::Http::Default.new
    client.read_timeout = 180
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400],
                         options: { http_client: client } do |options|
      options.binary = ENV.fetch('CHROME_BINARY') if ENV['CHROME_BINARY'].present?
      options.page_load_strategy = :eager
      options.add_argument('--no-sandbox')
      options.add_argument('--disable-dev-shm-usage')
      options.add_preference('credentials_enable_service', false)
      options.add_preference('profile.password_manager_enabled', false)
      options.add_preference('profile.password_manager_leak_detection', false)
    end
  end

  setup do
    skip 'A demonstração visual requer Selenium' if Capybara.current_driver == :rack_test
    @previous_wait = Capybara.default_max_wait_time
    Capybara.default_max_wait_time = 15
    @week = seed_demo(images: true).week
  end

  teardown { Capybara.default_max_wait_time = @previous_wait if @previous_wait }

  # rubocop:disable-next Minitest/MultipleAssertions
  test 'client sees service photos and opens a paid booking ready to reschedule' do
    visit vitrine_path

    assert_text 'Corte e barba'
    assert_text 'Barba e cuidado facial'
    assert_text 'Corte clássico'
    assert_local_images_loaded
    login_demo(:client)
    appointment = demo_record(Appointment, "#{@week}/appointment/0")
    visit appointment_path(appointment)

    assert_link 'Reagendar', href: edit_appointment_path(appointment)
    click_link 'Reagendar'

    assert_selector 'select#appointment_hour'
  end

  # rubocop:disable-next Minitest/MultipleAssertions
  test 'provider sees bookings blocks and the configured schedule' do
    login_demo(:provider)
    visit provider_calendar_path

    assert_selector '.fc-timeGridWeek-view'
    steps = (@week - Date.current.beginning_of_week(:sunday)).to_i / 7
    steps.times { find('.fc-next-button').click }

    assert_selector '.fc-event', text: 'Corte e barba'
    assert_selector '.fc-event', text: 'Bloqueio'
    visit provider_availability_path

    assert_text 'Organização do espaço'
    assert_text 'Manutenção dos materiais de barba'
  end

  # rubocop:disable-next Minitest/MultipleAssertions
  test 'administrator sees fictional users photos and an archived service' do
    login_demo(:admin)
    visit admin_users_path

    assert_text 'Marina Costa'
    assert_text 'Rafael Almeida'
    assert_local_images_loaded
    visit admin_services_path

    assert_text 'Pacote especial'
    assert_button 'Reativar'
    assert_local_images_loaded
  end

  private

  def login_demo(role)
    visit new_user_session_path
    fill_in 'E-mail', with: Demo::Catalog::USERS.fetch(role).fetch(:email)
    fill_in 'Senha', with: demo_env.fetch("DEMO_#{role.to_s.upcase}_PASSWORD")
    click_button 'Entrar'

    assert_current_path(role == :admin ? appointments_path : root_path, wait: 10)
  end

  def assert_local_images_loaded
    assert_selector 'img[src*="/rails/active_storage/"]'
    loaded = page.evaluate_async_script(<<~JS)
      const done = arguments[0];
      const images = Array.from(document.querySelectorAll('img[src*="/rails/active_storage/"]'));
      Promise.all(images.map(image => image.decode().then(() => image.naturalWidth > 0).catch(() => false)))
        .then(results => done(results.every(Boolean)));
    JS
    assert loaded, 'As imagens da demonstração devem carregar do armazenamento local de teste'
  end
end
