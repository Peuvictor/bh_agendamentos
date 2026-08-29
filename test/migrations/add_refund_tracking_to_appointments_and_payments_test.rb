# frozen_string_literal: true

require 'test_helper'

class AddRefundTrackingToAppointmentsAndPaymentsTest < ActiveSupport::TestCase
  test 'adds nullable refund audit timestamps without backfilling records' do
    assert Appointment.columns_hash.fetch('refunded_at').null
    assert Payment.columns_hash.fetch('refunded_at').null
    assert [appointments(:one).refunded_at, payments(:one).refunded_at].all?(&:nil?)
  end
end
