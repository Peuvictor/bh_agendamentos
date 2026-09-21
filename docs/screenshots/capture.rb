# frozen_string_literal: true

# Manual documentation task, intentionally outside the regular test suite.
abort 'Execute com RAILS_ENV=test e SYSTEM_TEST_DRIVER=selenium.' unless
  ENV['RAILS_ENV'] == 'test' && ENV['SYSTEM_TEST_DRIVER'] == 'selenium'

require 'application_system_test_case'
require 'base64'

# Keep this manual capture workflow together, including its example data.
# rubocop:disable-next Metrics/ClassLength
class DocumentationCapture < ApplicationSystemTestCase
  # Allow a cold asset build without changing the regular system test driver.
  client = Selenium::WebDriver::Remote::Http::Default.new
  client.read_timeout = 180
  driven_by :selenium, using: :headless_chrome, screen_size: [1440, 900], options: { http_client: client } do |options|
    options.binary = ENV.fetch('CHROME_BINARY') if ENV['CHROME_BINARY'].present?
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_preference('credentials_enable_service', false)
    options.add_preference('profile.password_manager_enabled', false)
    options.add_preference('profile.password_manager_leak_detection', false)
  end

  test 'capture the portfolio pages with fictional data' do
    page.driver.browser.manage.timeouts.script_timeout = 120
    prepare_examples
    viewport(1440)
    visit vitrine_path
    assert_text 'Corte e barba'
    capture('desktop-vitrine')

    login(@client)
    visit appointment_path(@appointment)
    assert_link 'Reagendar'
    capture('desktop-agendamento')

    login(@provider)
    open_calendar('.fc-timeGridWeek-view')
    capture('desktop-calendario')

    viewport(390)
    visit provider_availability_path
    assert_text 'Agenda de atendimento'
    capture('mobile-disponibilidade')

    open_calendar('.fc-timeGridDay-view')
    capture('mobile-calendario')

    login(@admin, password: 'Teste123!')
    visit admin_services_path
    assert_text 'Gestão de Serviços'
    assert_button 'Reativar'
    capture('mobile-administracao')
  end

  private

  def prepare_examples
    prepare_users
    @day = Date.current.next_occurring(:monday)
    prepare_schedule
    prepare_services
    prepare_appointments
  end

  def prepare_users
    @provider = users(:one)
    @provider.update!(nome: 'Rafael Almeida', bairro: 'Savassi')
    @client = users(:two)
    @client.update!(nome: 'Marina Costa')
    @admin = User.create!(nome: 'Administrador Demo', email: 'admin-docs@example.com',
                          password: 'Teste123!', role: :admin)
  end

  def prepare_schedule
    @provider.availability_periods.destroy_all
    (1..6).each do |weekday|
      [[480, 720], [840, 1080]].each do |starts, ends|
        @provider.availability_periods.create!(weekday: weekday, start_minute: starts, end_minute: ends)
      end
    end
  end

  def prepare_services
    services(:one).update!(nome: 'Corte e barba',
                           descricao: 'Corte personalizado e barba com acabamento à navalha.', duration: 60, preco: 85)
    services(:two).update!(user: @provider, nome: 'Barba e cuidado facial',
                           descricao: 'Um momento de cuidado com toalha quente e hidratação.', duration: 60, preco: 55)
    Review.find_each { |review| review.update!(rating: 5) }
    prepare_extra_services
  end

  def prepare_extra_services
    @provider.services.create!(nome: 'Corte clássico', descricao: 'Estilo e praticidade para o dia a dia.',
                               duration: 60, preco: 50)
    archived = @provider.services.create!(nome: 'Pacote especial', descricao: 'Oferta sazonal encerrada.',
                                          duration: 60, preco: 120)
    archived.archive!
  end

  def prepare_appointments
    @appointment = paid_appointment(services(:one), @day, 9)
    paid_appointment(services(:two), @day + 1, 10)
    paid_appointment(services(:one), @day + 2, 14)
    Appointment.create!(client: @client, service: services(:two), start_time: at(@day, 11), status: :pendente)
    @provider.availability_blocks.create!(starts_at: at(@day, 15), ends_at: at(@day, 16),
                                          reason: 'Organização do espaço')
  end

  def paid_appointment(service, date, hour)
    appointment = Appointment.create!(client: @client, service: service, start_time: at(date, hour),
                                      status: :confirmado)
    Payment.create!(appointment: appointment, amount: service.preco, status: :aprovado,
                    mp_transaction_id: SecureRandom.uuid, idempotency_key: SecureRandom.uuid)
    appointment
  end

  def at(date, hour)
    Time.zone.local(date.year, date.month, date.day, hour)
  end

  def viewport(width)
    page.driver.browser.execute_cdp('Emulation.setDeviceMetricsOverride',
                                    width: width, height: 900, deviceScaleFactor: 1, mobile: false)
  end

  def login(user, password: 'password123')
    Capybara.reset_sessions!
    visit new_user_session_path
    fill_in 'E-mail', with: user.email
    fill_in 'Senha', with: password
    click_button 'Entrar'
    assert_current_path(user.admin? ? appointments_path : root_path, wait: 10)
  end

  def open_calendar(view)
    visit provider_calendar_path
    assert_selector view
    steps = if view == '.fc-timeGridWeek-view'
              (@day - Date.current.beginning_of_week(:sunday)).to_i / 7
            else
              (@day - Date.current).to_i
            end
    steps.times { find('.fc-next-button').click }
    assert_selector '.fc-event', text: 'Corte e barba'
    assert_selector '.fc-event', text: 'Bloqueio'
  end

  def capture(name)
    wait_for_render
    assert_equal true, page.evaluate_script('Array.from(document.images).every(i => i.complete && i.naturalWidth > 0)')
    Rails.root.join("docs/screenshots/#{name}.png").binwrite(full_page_image)
    puts "Captura salva: #{name}.png"
  end

  def wait_for_render
    page.evaluate_async_script(<<~JS)
      const done = arguments[0];
      document.fonts.ready.then(() => requestAnimationFrame(() => requestAnimationFrame(done)));
    JS
  end

  def full_page_image
    size = page.driver.browser.execute_cdp('Page.getLayoutMetrics').fetch('cssContentSize')
    result = page.driver.browser.execute_cdp('Page.captureScreenshot', format: 'png',
                                                                       captureBeyondViewport: true,
                                                                       clip: { x: 0, y: 0, width: size.fetch('width'),
                                                                               height: size.fetch('height'), scale: 1 })
    Base64.decode64(result.fetch('data'))
  end
end
