# frozen_string_literal: true

require 'application_system_test_case'
require_relative '../support/mobile_browser_helpers'
require_relative '../support/rescheduling_setup'

# rubocop:disable-next Minitest/MultipleAssertions, Metrics/BlockLength
class MobilePaymentTest < ApplicationSystemTestCase
  include MobileBrowserHelpers
  include ReschedulingSetup

  setup do
    skip 'Interações mobile requerem Selenium' if Capybara.current_driver == :rack_test
    mobile_viewport(320)
  end

  teardown do
    page.driver.browser.execute_cdp('Emulation.clearDeviceMetricsOverride') unless Capybara.current_driver == :rack_test
  end

  test 'client reserves a slot and sees simulated payment states' do
    mobile_login(users(:two))
    visit new_service_appointment_path(services(:one))
    set_native_field('Dia do Agendamento', 10.days.from_now.to_date.iso8601)
    select '11:30', from: 'Horário Disponível'
    click_button 'Confirmar Agendamento'

    assert_text 'Horário reservado'
    assert_mobile_fit
    assert_predicate users(:two).appointments.order(created_at: :desc).first, :pendente?
    # Exercise our own payment UI with a fake gateway response. No payment request leaves the browser.
    page.execute_script(<<~JS)
      window.mobilePayment = window.Stimulus.getControllerForElementAndIdentifier(document.querySelector('[data-controller="payment"]'), 'payment');
      window.mobilePayment.clearInitializationTimeout();
      window.fetch = async () => ({ ok: true, json: async () => ({ status: 'pending', detail: { point_of_interaction: {
        transaction_data: { qr_code: '000201' + '1234567890'.repeat(40), qr_code_base64: 'R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==' }
      } } }) });
      window.mobilePayment.submitPayment('pix', {});
    JS

    assert_selector '[data-role="pix-code"]'
    assert_mobile_fit
    capture_mobile('mobile-pix')
    page.execute_script(<<~JS)
      window.fetch = async () => ({ ok: false, json: async () => ({ error: 'Pagamento recusado. Confira os dados.' }) });
      window.mobilePayment.submitPayment('credit_card', {}).catch(() => {});
    JS

    assert_text 'Pagamento recusado'
    assert_mobile_fit
    page.execute_script(<<~JS)
      window.fetch = async () => ({ ok: true, json: async () => ({ status: 'approved' }) });
      window.mobilePayment.submitPayment('credit_card', {});
    JS

    assert_text 'Pagamento aprovado!'
    assert_mobile_fit
  end
end
