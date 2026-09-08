# frozen_string_literal: true

require 'application_system_test_case'

class AvailabilityBlockEditingTest < ApplicationSystemTestCase
  setup do
    @provider = users(:one)
    @block = @provider.availability_blocks.create!(
      starts_at: 7.days.from_now.beginning_of_day, ends_at: 8.days.from_now.beginning_of_day, reason: 'Feriado'
    )
    visit new_user_session_path
    fill_in 'E-mail', with: @provider.email
    fill_in 'Senha', with: 'password123'
    click_button 'Entrar'
  end

  # rubocop:disable-next Minitest/MultipleAssertions
  test 'provider edits a block through availability and sees the persisted values' do
    visit provider_availability_path
    click_link 'Editar', href: edit_provider_availability_block_path(@block)
    uncheck 'Dia inteiro'
    fill_in 'De', with: '13:00'
    fill_in 'Até', with: '14:00'
    fill_in 'Motivo (opcional)', with: 'Manutenção'
    click_button 'Salvar alterações'

    assert_text 'Bloqueio atualizado com sucesso'
    visit edit_provider_availability_block_path(@block)

    assert_field 'Motivo (opcional)', with: 'Manutenção'
    assert_field 'De', with: '13:00'
    assert_field 'Até', with: '14:00'
  end

  test 'provider opens editing through calendar and reloads the updated event' do
    skip 'Interação do calendário requer Selenium' if Capybara.current_driver == :rack_test
    visit provider_calendar_path
    find('.fc-next-button').click
    find('.fc-event', text: 'Bloqueio').click
    click_link 'Editar bloqueio'
    fill_in 'Motivo (opcional)', with: 'Feriado atualizado'
    click_button 'Salvar alterações'

    assert_text 'Bloqueio atualizado com sucesso'
    visit provider_calendar_path
    find('.fc-next-button').click
    find('.fc-event', text: 'Bloqueio').click

    assert_selector 'dialog[open]', text: 'Feriado atualizado'
    assert_link 'Editar bloqueio', href: edit_provider_availability_block_path(@block)
  end
end
