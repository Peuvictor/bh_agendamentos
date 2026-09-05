# frozen_string_literal: true

require 'test_helper'

module Provider
  class AvailabilityControllerTest < ActionDispatch::IntegrationTest
    setup do
      @provider = users(:one)
      sign_in @provider
    end

    test 'shows the schedule management page to a provider' do
      get provider_availability_url

      assert_response :success
      assert_select 'h1', text: 'Agenda de atendimento'
      assert_select "form[action='#{provider_availability_path}']"
    end

    test 'offers dynamic turns for every weekday' do
      get provider_availability_url

      assert_select "[data-controller='schedule-periods']", count: 7
      assert_select "button[data-action='schedule-periods#add']", text: /Adicionar turno/, count: 7
    end

    # rubocop:disable-next Minitest/MultipleAssertions
    test 'omits archived services from the new block selector but keeps their existing blocks visible' do
      service = services(:one)
      block = @provider.availability_blocks.create!(
        service: service,
        starts_at: 2.days.from_now.beginning_of_day,
        ends_at: 2.days.from_now.beginning_of_day + 1.hour
      )
      service.archive!

      get provider_availability_url

      assert_response :success
      assert_select "select[name='availability_block[service_id]'] option[value='#{service.id}']", count: 0
      assert_select "form[action='#{provider_availability_block_path(block)}']"
      assert_match service.nome, response.body
    end

    test 'saves more than two turns on the same day' do
      patch provider_availability_url, params: {
        schedule: {
          '1' => { periods: {
            '0' => { start: '08:00', end: '10:00' },
            '1' => { start: '11:00', end: '12:00' },
            '2' => { start: '13:00', end: '14:00' },
            '3' => { start: '15:00', end: '16:00' }
          } }
        }
      }

      assert_redirected_to provider_availability_url
      assert_equal [[480, 600], [660, 720], [780, 840], [900, 960]], ranges_for(1)
    end

    test 'replaces weekly periods and allows a closed day' do
      patch provider_availability_url, params: {
        schedule: {
          '1' => { periods: {
            '0' => { start: '08:00', end: '12:00' },
            '1' => { start: '13:00', end: '16:00' }
          } },
          '6' => { periods: { '0' => { start: '08:00', end: '12:00' } } }
        }
      }

      assert_redirected_to provider_availability_url
      expected_ranges = { 1 => [[480, 720], [780, 960]], 6 => [[480, 720]] }

      assert_equal expected_ranges, { 1 => ranges_for(1), 6 => ranges_for(6) }
      assert_empty @provider.availability_periods.where(weekday: 0)
    end

    test 'rejects overlapping weekly periods without losing the previous schedule' do
      previous_count = @provider.availability_periods.count

      patch provider_availability_url, params: {
        schedule: {
          '1' => { periods: {
            '0' => { start: '08:00', end: '12:00' },
            '1' => { start: '11:00', end: '16:00' }
          } }
        }
      }

      assert_redirected_to provider_availability_url
      assert_equal previous_count, @provider.availability_periods.count
      assert_equal 'Os períodos do mesmo dia não podem se sobrepor', flash[:alert]
    end

    test 'rejects a client' do
      sign_out @provider
      sign_in users(:two)

      get provider_availability_url

      assert_redirected_to root_url
    end

    private

    def ranges_for(weekday)
      @provider.availability_periods.where(weekday: weekday).ordered.pluck(:start_minute, :end_minute)
    end
  end
end
