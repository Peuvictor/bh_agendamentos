# frozen_string_literal: true

class ProviderDashboardMetrics
  RECENT_REVENUE_DAYS = 30

  def initialize(provider:, now: Time.current)
    @provider = provider
    @now = now
  end

  def revenue_received
    approved_appointments.sum('payments.amount')
  end

  def revenue_expected
    active_pending_appointments.sum('COALESCE(payments.amount, services.preco)')
  end

  def average_ticket
    approved_appointments.average('payments.amount') || 0
  end

  def paying_clients_count
    approved_appointments.distinct.count(:client_id)
  end

  def daily_revenue
    approved_appointments
      .where(appointments: { start_time: recent_revenue_period })
      .group_by_day('appointments.start_time')
      .sum('payments.amount')
  end

  def appointments_by_status
    appointments.group(:status).count
  end

  private

  attr_reader :provider, :now

  def appointments
    Appointment.joins(:service).where(services: { user_id: provider.id })
  end

  def approved_appointments
    appointments
      .joins(:payment)
      .where(appointments: { status: :confirmado }, payments: { status: :aprovado })
  end

  def active_pending_appointments
    appointments
      .left_joins(:payment)
      .where(appointments: { status: :pendente })
      .where('appointments.start_time > ?', now)
      .where('appointments.expires_at > ?', now)
      .where(payments: { status: [nil, Payment.statuses.fetch('pendente')] })
  end

  def recent_revenue_period
    (now.beginning_of_day - (RECENT_REVENUE_DAYS - 1).days)..now
  end
end
