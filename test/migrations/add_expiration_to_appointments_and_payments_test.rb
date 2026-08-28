# frozen_string_literal: true

require 'test_helper'
require Rails.root.join('db/migrate/20260828170000_add_expiration_to_appointments_and_payments')

# The assertions cover all backfill groups in a single migration execution.
# rubocop:disable-next Minitest/MultipleAssertions
class AddExpirationToAppointmentsAndPaymentsTest < ActiveSupport::TestCase
  test 'backfills pending records without changing terminal records' do
    without_payment = create_appointment(start_time: 20.days.from_now)
    with_payment = create_appointment(start_time: 21.days.from_now)
    payment = Payment.create!(
      appointment: with_payment,
      amount: with_payment.service.preco,
      status: :pendente,
      mp_transaction_id: 'mp-backfill',
      idempotency_key: 'idempotency-backfill'
    )
    terminal = create_appointment(start_time: 22.days.from_now, status: :cancelado)

    without_payment.update!(expires_at: nil)
    with_payment.update!(expires_at: nil)
    payment.update!(expires_at: nil)

    AddExpirationToAppointmentsAndPayments.new.send(:backfill_pending_expirations)

    assert_in_delta without_payment.created_at + 30.minutes, without_payment.reload.expires_at, 1.second
    assert_in_delta payment.created_at + 30.minutes, payment.reload.expires_at, 1.second
    assert_in_delta payment.created_at + 30.minutes, with_payment.reload.expires_at, 1.second
    assert_nil terminal.reload.expires_at
  end

  private

  def create_appointment(start_time:, status: :pendente)
    Appointment.create!(
      client: users(:two),
      service: services(:one),
      start_time: start_time.change(hour: 10, min: 0),
      status: status
    )
  end
end
