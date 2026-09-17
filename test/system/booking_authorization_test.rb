# frozen_string_literal: true

require 'application_system_test_case'

class BookingAuthorizationTest < ApplicationSystemTestCase
  %i[provider admin].each do |role|
    test "#{role} sees the storefront without a booking action" do
      login_with_role(role)
      visit vitrine_path

      assert_text 'Exclusivo para clientes'
      assert_no_link 'Agendar'
    end

    test "#{role} cannot access the booking form through a direct URL" do
      login_with_role(role)
      visit new_service_appointment_path(services(:one))

      assert_current_path vitrine_path
      assert_text 'Apenas clientes podem agendar serviços.'
      assert_no_button 'Confirmar Agendamento'
    end
  end

  private

  def login_with_role(role)
    user = User.create!(nome: 'Conta sem permissão de reserva', email: "#{role}-browser@example.com",
                        password: 'password123', role: role)
    visit new_user_session_path
    fill_in 'E-mail', with: user.email
    fill_in 'Senha', with: 'password123'
    click_button 'Entrar'

    assert_text 'Login efetuado com sucesso'
  end
end
