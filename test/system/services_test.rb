require "application_system_test_case"

class ServicesTest < ApplicationSystemTestCase
  setup do
    @provider = users(:one)
    @service = services(:one)

    visit new_user_session_path
    fill_in "E-mail", with: @provider.email
    fill_in "Senha", with: "password123"
    click_button "Entrar"
  end

  test "provider sees active and archived service sections" do
    visit services_path

    assert_selector "h1", text: "Meus Serviços"
    assert_selector "h2", text: "Serviços ativos"
    assert_selector "h2", text: "Serviços arquivados"
  end

  test "provider creates and updates a service" do
    visit services_path
    click_on "+ Novo Serviço"

    fill_in "Nome do Serviço", with: "Barba completa"
    fill_in "Descrição", with: "Atendimento completo"
    fill_in "Duração do Serviço", with: 45
    fill_in "Preço do Serviço", with: 75
    click_button "Salvar Serviço"

    assert_text "Serviço criado com sucesso"
    click_on "Editar", match: :first
    fill_in "Nome do Serviço", with: "Barba premium"
    click_button "Salvar Serviço"

    assert_text "Serviço atualizado com sucesso"
    assert_text "Barba premium"
  end

  # rubocop:disable-next Minitest/MultipleAssertions
  test "provider archives and reactivates a service without deleting it" do
    visit services_path

    click_button "Arquivar"

    assert_text "Serviço arquivado. O histórico foi preservado."
    assert_text @service.nome
    assert_selector "h2", text: "Serviços arquivados"
    assert_button "Reativar"

    click_button "Reativar"

    assert_text "Serviço reativado com sucesso."
    assert_text @service.nome
    assert_button "Arquivar"
    assert Service.exists?(@service.id)
  end
end
