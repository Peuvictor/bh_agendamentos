class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_provider!

  def index
    metrics = ProviderDashboardMetrics.new(provider: current_user)

    @faturamento_realizado = metrics.revenue_received
    @faturamento_previsto = metrics.revenue_expected
    @ticket_medio = metrics.average_ticket
    @clientes_pagantes = metrics.paying_clients_count
    @faturamento_diario = metrics.daily_revenue
    @agendamentos_por_status = metrics.appointments_by_status
  end

  private

  def ensure_provider!
    return if current_user.provider? || current_user.admin?

    redirect_to root_path, alert: "Acesso restrito para prestadores."
  end
end
