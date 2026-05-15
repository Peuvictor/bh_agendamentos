class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_provider!

  def index
    # Busca apenas os agendamentos onde o usuário atual é o dono do serviço
    @meus_agendamentos = Appointment.joins(:service).where(services: { user_id: current_user.id })

    # --- MÉTRICAS FINANCEIRAS ---

    # Dinheiro no bolso (Agendamentos finalizados)
    # *Atenção: verifique se o seu status de finalizado no banco é "concluido" (ou "completed", etc)*
    @faturamento_realizado = @meus_agendamentos.where(status: 'concluido').sum('services.preco')

    # Dinheiro na mesa (Agendamentos futuros, excluindo cancelados e já concluídos)
    @faturamento_previsto = @meus_agendamentos.where.not(status: ['cancelado', 'concluido']).sum('services.preco')

    # Ticket Médio (Média de valor dos serviços vendidos válidos)
    total_agendamentos = @meus_agendamentos.where.not(status: 'cancelado').count
    @ticket_medio = total_agendamentos.positive? ? (@faturamento_realizado + @faturamento_previsto) / total_agendamentos : 0

    # --- GRÁFICOS (Chartkick + Groupdate) ---

    @faturamento_diario = @meus_agendamentos
                            .group_by_day('appointments.start_time')
                            .sum('services.preco')

    @agendamentos_por_status = @meus_agendamentos.group(:status).count
  end

  private

  # Trava: Se o cliente tentar acessar a URL /dashboard, ele é chutado de volta
  def ensure_provider!
    unless current_user.provider? || current_user.admin?
      redirect_to root_path, alert: "Acesso restrito para prestadores."
    end
  end
end
