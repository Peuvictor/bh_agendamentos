# frozen_string_literal: true

require 'test_helper'

module Provider
  # rubocop:disable-next Metrics/ClassLength, Minitest/MultipleAssertions
  class AvailabilityBlockEditingTest < ActionDispatch::IntegrationTest
    setup do
      travel_to Time.zone.local(2026, 10, 5, 10)
      @provider = users(:one)
      @block = @provider.availability_blocks.create!(
        starts_at: 1.day.from_now.change(hour: 13), ends_at: 1.day.from_now.change(hour: 15), reason: 'Original'
      )
      sign_in @provider
    end

    teardown { travel_back }

    test 'prefills the form and updates the same record and availability' do
      service = services(:one)
      date = @block.starts_at.to_date
      get edit_provider_availability_block_url(@block)

      assert_select 'input[name="availability_block[start_time]"][value="13:00"]'
      assert_not_includes ProviderAvailability.new(service: service, date: date).slots, '13:00'
      created_at = @block.created_at
      update_block(start_time: '15:00', end_time: '16:00', service_id: service.id, reason: 'Manutenção')

      assert_redirected_to provider_availability_url
      assert_equal [created_at, 'Manutenção', service.id],
                   @block.reload.attributes.values_at('created_at', 'reason', 'service_id')
      assert_includes ProviderAvailability.new(service: service, date: date).slots, '13:00'
      assert_not_includes ProviderAvailability.new(service: service, date: date).slots, '15:00'
    end

    test 'converts to all day and back to partial on another date' do
      update_block(all_day: '1', service_id: services(:one).id)

      assert_predicate @block.reload, :all_day?
      update_block(date: 2.days.from_now.to_date.iso8601, service_id: '', start_time: '09:00', end_time: '10:00')

      assert_redirected_to provider_availability_url
      assert_equal [2.days.from_now.to_date, nil, '09:00'],
                   [@block.reload.starts_at.to_date, @block.service_id, @block.starts_at.strftime('%H:%M')]
    end

    test 'invalid input preserves the database and submitted fields' do
      original = @block.attributes
      update_block(start_time: '16:00', end_time: '14:00', reason: 'Novo motivo')

      assert_response :unprocessable_content
      assert_select 'input[name="availability_block[reason]"][value="Novo motivo"]'
      assert_select 'input[name="availability_block[start_time]"][value="16:00"]'
      assert_equal original, @block.reload.attributes
    end

    test 'malformed dates and times render validation errors' do
      update_block(date: 'data-invalida')

      assert_response :unprocessable_content
      update_block(start_time: '25:00')

      assert_response :unprocessable_content
      assert_equal 'Original', @block.reload.reason
    end

    test 'reason length is validated on the server' do
      update_block(reason: 'x' * 151)

      assert_response :unprocessable_content
      assert_equal 'Original', @block.reload.reason
    end

    test 'ended blocks reject both entry and submission' do
      travel_to @block.ends_at
      get edit_provider_availability_block_url(@block)

      assert_redirected_to provider_availability_url
      update_block(date: 2.days.from_now.to_date.iso8601)

      assert_redirected_to provider_availability_url
      assert_equal 'Original', @block.reload.reason
    end

    test 'a block ending after the form was opened cannot be updated' do
      get edit_provider_availability_block_url(@block)

      assert_response :success
      travel_to @block.ends_at + 1.second
      update_block(date: 2.days.from_now.to_date.iso8601)

      assert_equal I18n.t('provider.availability_blocks.ended'), flash[:alert]
      assert_equal 'Original', @block.reload.reason
    end

    test 'ongoing block retains its original start but rejects a changed past start' do
      travel_to @block.starts_at + 30.minutes
      update_block(reason: 'Em andamento')

      assert_redirected_to provider_availability_url
      update_block(start_time: '12:00')

      assert_response :unprocessable_content
      assert_equal ['13:00', 'Em andamento'], [@block.reload.starts_at.strftime('%H:%M'), @block.reason]
    end

    test 'today all day is allowed but past dates and expired endings are rejected' do
      update_block(date: Date.current.iso8601, all_day: '1')

      assert_redirected_to provider_availability_url
      update_block(date: Date.yesterday.iso8601, all_day: '1')

      assert_response :unprocessable_content
      update_block(date: Date.current.iso8601, start_time: '00:00', end_time: '09:00')

      assert_response :unprocessable_content
      assert_predicate @block.reload, :all_day?
    end

    test 'keeps the archived original service but rejects a different archived service' do
      service = services(:one)
      @block.update!(service: service)
      service.archive!
      get edit_provider_availability_block_url(@block)

      assert_select 'option', text: "#{service.nome} (arquivado)"
      update_block(service_id: service.id, reason: 'Vínculo preservado')

      assert_redirected_to provider_availability_url
      other = @provider.services.create!(nome: 'Outro serviço', duration: 30, preco: 40)
      other.archive!
      update_block(service_id: other.id)

      assert_response :not_found
      assert_equal service.id, @block.reload.service_id
    end

    test 'allows changing an archived original service to active or all services' do
      @block.update!(service: services(:one))
      services(:one).archive!
      other = @provider.services.create!(nome: 'Serviço ativo', duration: 30, preco: 40)
      update_block(service_id: other.id)

      assert_equal other.id, @block.reload.service_id
      update_block(service_id: '')

      assert_nil @block.reload.service_id
    end

    test 'another providers block or service cannot be edited' do
      foreign_block = users(:two).availability_blocks.create!(starts_at: @block.starts_at, ends_at: @block.ends_at)
      get edit_provider_availability_block_url(foreign_block)

      assert_response :not_found
      sign_in @provider
      patch provider_availability_block_url(foreign_block), params: { availability_block: { reason: 'Indevido' } }

      assert_response :not_found
      sign_in @provider
      update_block(service_id: services(:two).id)

      assert_response :not_found
      assert_nil @block.reload.service_id
    end

    test 'clients administrators and anonymous visitors cannot edit' do
      sign_out @provider
      get edit_provider_availability_block_url(@block)

      assert_redirected_to new_user_session_url
      sign_in users(:two)
      update_block

      assert_redirected_to root_url
      users(:two).update!(role: :admin)
      get edit_provider_availability_block_url(@block)

      assert_redirected_to root_url
      assert_equal 'Original', @block.reload.reason
    end

    test 'moving a block over a reservation preserves the reservation and other blocks' do
      appointment = Appointment.create!(
        client: users(:two), service: services(:one), start_time: @block.starts_at - 2.hours
      )
      original = appointment.attributes
      @provider.availability_blocks.create!(starts_at: @block.starts_at, ends_at: @block.ends_at)
      update_block(start_time: '11:00', end_time: '12:00')

      assert_redirected_to provider_availability_url
      assert_equal original, appointment.reload.attributes
      slots = ProviderAvailability.new(service: services(:one), date: @block.starts_at.to_date).slots

      assert_not_includes slots, '13:00'
    end

    private

    def update_block(**overrides)
      values = { date: @block.starts_at.to_date.iso8601, all_day: '0', start_time: '13:00',
                 end_time: '15:00', service_id: '', reason: 'Alterado' }
      patch provider_availability_block_url(@block), params: { availability_block: values.merge(overrides) }
    end
  end
end
