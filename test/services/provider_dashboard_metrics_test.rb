# frozen_string_literal: true

require 'test_helper'

class ProviderDashboardMetricsTest < ActiveSupport::TestCase
  setup do
    @provider = users(:one)
    @client = users(:two)
    @now = Time.current.change(hour: 10, min: 0, sec: 0, usec: 0)
    @metrics = ProviderDashboardMetrics.new(provider: @provider, now: @now)
  end

  test 'groups only approved revenue from the last 30 days' do
    recent_appointment = create_historical_appointment(start_time: @now - 5.days)
    old_appointment = create_historical_appointment(start_time: @now - 31.days)
    create_payment(appointment: recent_appointment, amount: 75)
    create_payment(appointment: old_appointment, amount: 90)

    daily_revenue = @metrics.daily_revenue

    assert_equal 75.to_d, daily_revenue.fetch((@now - 5.days).to_date)
    assert_not daily_revenue.key?((@now - 31.days).to_date)
  end

  test 'counts each paying client only once' do
    first_appointment = create_confirmed_appointment(start_time: @now + 5.days)
    second_appointment = create_confirmed_appointment(start_time: @now + 6.days)
    create_payment(appointment: first_appointment, amount: 40)
    create_payment(appointment: second_appointment, amount: 60)

    assert_equal 1, @metrics.paying_clients_count
    assert_equal 50.to_d, @metrics.average_ticket
  end

  test 'keeps archived service appointments in provider metrics' do
    appointment = create_confirmed_appointment(start_time: @now + 5.days)
    create_payment(appointment: appointment, amount: 85)
    appointment.service.archive!

    assert_equal 85.to_d, @metrics.revenue_received
    assert_equal 1, @metrics.appointments_by_status.fetch('confirmado')
  end

  private

  def create_confirmed_appointment(start_time:)
    Appointment.create!(
      client: @client,
      service: services(:one),
      start_time: start_time,
      status: :confirmado
    )
  end

  def create_payment(appointment:, amount:)
    Payment.create!(
      appointment: appointment,
      amount: amount,
      status: :aprovado,
      mp_transaction_id: "metrics-#{SecureRandom.uuid}",
      idempotency_key: "metrics-#{SecureRandom.uuid}"
    )
  end

  def create_historical_appointment(start_time:)
    travel_to(start_time - 1.day) do
      create_confirmed_appointment(start_time: start_time)
    end
  end
end
