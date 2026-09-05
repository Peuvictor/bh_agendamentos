# frozen_string_literal: true

require 'test_helper'

module Provider
  class AvailabilityBlocksControllerTest < ActionDispatch::IntegrationTest
    setup do
      @provider = users(:one)
      sign_in @provider
    end

    test 'creates an all-day block for every service' do
      date = 3.days.from_now.to_date

      assert_difference('@provider.availability_blocks.count', 1) do
        post provider_availability_blocks_url, params: {
          availability_block: {
            date: date.iso8601,
            all_day: '1',
            reason: 'Feriado'
          }
        }
      end

      block = @provider.availability_blocks.order(:created_at).last

      assert_equal [nil, date, block.starts_at + 1.day], [block.service, block.starts_at.to_date, block.ends_at]
      assert_redirected_to provider_availability_url
    end

    test 'creates a partial block for one owned service' do
      date = 4.days.from_now.to_date

      post provider_availability_blocks_url, params: {
        availability_block: {
          date: date.iso8601,
          all_day: '0',
          start_time: '13:00',
          end_time: '15:30',
          service_id: services(:one).id,
          reason: 'Serviço indisponível'
        }
      }

      block = @provider.availability_blocks.order(:created_at).last

      assert_equal services(:one), block.service
      assert_equal '13:00', block.starts_at.strftime('%H:%M')
      assert_equal '15:30', block.ends_at.strftime('%H:%M')
    end

    test 'does not accept another providers service' do
      assert_no_difference('AvailabilityBlock.count') do
        post provider_availability_blocks_url, params: {
          availability_block: {
            date: 5.days.from_now.to_date.iso8601,
            all_day: '1',
            service_id: services(:two).id
          }
        }
      end

      assert_response :not_found
    end

    test 'does not accept an archived owned service' do
      service = services(:one)
      service.archive!

      assert_no_difference('AvailabilityBlock.count') do
        post provider_availability_blocks_url, params: {
          availability_block: {
            date: 5.days.from_now.to_date.iso8601,
            all_day: '1',
            service_id: service.id
          }
        }
      end

      assert_response :not_found
    end

    test 'removes an owned block' do
      block = @provider.availability_blocks.create!(
        starts_at: 2.days.from_now.beginning_of_day,
        ends_at: 3.days.from_now.beginning_of_day
      )

      assert_difference('AvailabilityBlock.count', -1) do
        delete provider_availability_block_url(block)
      end

      assert_redirected_to provider_availability_url
    end
  end
end
