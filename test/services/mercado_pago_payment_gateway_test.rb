# frozen_string_literal: true

require 'test_helper'

class MercadoPagoPaymentGatewayTest < ActiveSupport::TestCase
  test 'rejects a non-successful HTTP response' do
    payment_api = Minitest::Mock.new
    payment_api.expect :get, { status: 503, response: {} }, ['mp-unavailable']
    gateway = MercadoPagoPaymentGateway.new(sdk: sdk_with(payment_api))

    error = assert_raises(MercadoPagoPaymentGateway::InvalidResponseError) do
      gateway.fetch_payment('mp-unavailable')
    end

    assert_includes error.message, 'HTTP 503'
    payment_api.verify
  end

  test 'cancels through the official payment update resource' do
    response = { 'id' => 'mp-cancel', 'status' => 'cancelled' }
    payment_api = Minitest::Mock.new
    payment_api.expect :update, { status: 200, response: response }, ['mp-cancel', { status: 'cancelled' }]
    gateway = MercadoPagoPaymentGateway.new(sdk: sdk_with(payment_api))

    assert_equal response, gateway.cancel_payment('mp-cancel')
    payment_api.verify
  end

  private

  def sdk_with(payment_api)
    Object.new.tap do |sdk|
      sdk.define_singleton_method(:payment) { payment_api }
    end
  end
end
