class Admin::DashboardController < ApplicationController
  # Trava dupla de segurança: Tem que estar logado E ser Admin
  before_action :authenticate_user!
  before_action :authorize_admin!

  def index
    # Coletando métricas para os Cards do Tailwind
    @total_clientes = User.client.count
    @total_prestadores = User.provider.count
    @total_agendamentos = Appointment.count

    # Trazendo os últimos 10 agendamentos com os dados de cliente e serviço para não sobrecarregar o banco (N+1 query)
    @agendamentos_recentes = Appointment.includes(:client, :service).order(created_at: :desc).limit(10)
  end
end
