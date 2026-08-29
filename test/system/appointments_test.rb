require "application_system_test_case"

class AppointmentsTest < ApplicationSystemTestCase
  setup do
    @client = users(:two)
    @service = services(:one)
    @previous_public_key = ENV["MERCADO_PAGO_PUBLIC_KEY"]
    ENV["MERCADO_PAGO_PUBLIC_KEY"] ||= "TEST-system-public-key"
  end

  teardown do
    ENV["MERCADO_PAGO_PUBLIC_KEY"] = @previous_public_key
  end

  test "client creates an appointment and reaches the configured checkout" do
    visit new_user_session_path
    fill_in "E-mail", with: @client.email
    fill_in "Senha", with: "password123"
    click_button "Entrar"

    visit new_service_appointment_path(@service)
    appointment_date = 10.days.from_now.to_date.iso8601
    fill_in "Dia do Agendamento", with: appointment_date
    # Date inputs do not consistently emit `change` in headless Chrome when
    # Capybara sets their value; trigger it so the available slots refresh.
    page.execute_script("document.getElementById('appointment_date').dispatchEvent(new Event('change', { bubbles: true }))") if Capybara.current_driver != :rack_test
    select "11:30", from: "Horário Disponível"
    click_button "Confirmar Agendamento"

    assert_text "Horário reservado. Conclua o pagamento para confirmar o agendamento."
    assert_text "Concluir Agendamento"
    assert_selector "meta[name='mp-public-key'][content='#{ENV.fetch("MERCADO_PAGO_PUBLIC_KEY")}']", visible: :all
    assert_selector "[data-controller='payment']"
    assert_selector "#paymentBrick_container"

    if Capybara.current_driver != :rack_test
      assert_no_selector "#paymentBrick_container .animate-pulse", wait: 15
    end
  end
end
