class AppointmentsController < ApplicationController
  before_action :authenticate_user!

  # 1. Configurações baseadas na Rota Aninhada
  before_action :set_service, only: %i[new create]
  before_action :set_appointment, only: %i[show edit update destroy]

  # 2. Carrega os horários apenas quando formos renderizar a tela
  before_action :set_available_slots, only: %i[new create edit update]
  before_action :set_busy_slots, only: %i[new create edit update]

  def index
    # Esta tela representa as reservas feitas pela conta. Prestadores consultam
    # os agendamentos recebidos separadamente no dashboard.
    @appointments = current_user.appointments.order(start_time: :asc)
  end

  def show
  end

  def new
    # O agendamento já nasce atrelado ao serviço da URL
    @appointment = @service.appointments.build
  end

  def create
    # Cria o agendamento em branco atrelado ao serviço atual
    @appointment = @service.appointments.build

    # A INJEÇÃO DE SEGURANÇA: O cliente é quem está logado.
    @appointment.client_id = current_user.id

    # A sua lógica de conversão de Data/Hora
    if params[:appointment_date].present? && params[:appointment_hour].present?
      begin
        combined_time = Time.zone.parse("#{params[:appointment_date]} #{params[:appointment_hour]}")
        @appointment.start_time = combined_time
      rescue ArgumentError
        @appointment.errors.add(:start_time, "inválido. Verifique a data e hora.")
      end
    end

    if @appointment.save
      redirect_to appointment_path(@appointment), notice: "Horário reservado. Conclua o pagamento para confirmar o agendamento."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to appointment_path(@appointment), alert: "Este agendamento não pode ser editado. Cancele e reserve um novo horário."
  end

  def update
    redirect_to appointment_path(@appointment), alert: "O status do agendamento não pode ser alterado por esta rota."
  end

  def destroy
    if @appointment.reembolsado?
      redirect_back fallback_location: appointments_path, alert: "Este agendamento foi reembolsado e não pode ser alterado."
    elsif @appointment.cancelado?
      redirect_back fallback_location: appointments_path, alert: "Este agendamento já está cancelado."
    elsif @appointment.start_time <= Time.current
      redirect_back fallback_location: appointments_path, alert: "Não é possível cancelar um agendamento que já começou."
    elsif @appointment.update(status: :cancelado)
      AppointmentMailer.cancellation_email(@appointment).deliver_later
      redirect_back fallback_location: appointments_path, notice: "Agendamento cancelado com sucesso. O horário já está livre!"
    else
      redirect_back fallback_location: appointments_path, alert: "Não foi possível cancelar o agendamento."
    end
  end

  def dashboard
    # Painel exclusivo do prestador
    @my_appointments = Appointment.joins(:service)
                                  .where(services: { user_id: current_user.id })
                                  .where("start_time >= ?", Time.current.beginning_of_day)
                                  .order(start_time: :asc)
  end

  def update_status
    @appointment = Appointment.find(params[:id])

    # Trava de Segurança: Só o prestador dono do serviço pode alterar
    if @appointment.service.user == current_user
      requested_status = params[:status].to_s

      unless %w[confirmado cancelado].include?(requested_status)
        return redirect_to dashboard_path, alert: "Status de agendamento inválido."
      end

      if requested_status == "confirmado" && !@appointment.payment&.aprovado?
        return redirect_to dashboard_path, alert: "O agendamento só pode ser confirmado após o pagamento aprovado."
      end

      if @appointment.update(status: requested_status)

        # 👇 GATILHO DO SIDEKIQ 👇
        if @appointment.saved_change_to_status? && @appointment.confirmado?
          AppointmentMailer.confirmation_email(@appointment).deliver_later
        elsif @appointment.saved_change_to_status? && @appointment.cancelado?
          AppointmentMailer.cancellation_email(@appointment).deliver_later
        end

        redirect_to dashboard_path, notice: "Status atualizado e cliente notificado por e-mail!"
      else
        redirect_to dashboard_path, alert: "Erro ao atualizar status."
      end
    else
      redirect_to dashboard_path, alert: "Você não tem permissão, uai!"
    end
  end
  private

  # NOVO: Busca o serviço com base na URL aninhada (ex: /services/5/appointments/new)
  def set_service
    @service = Service.find(params[:service_id])
  end

  def set_appointment
    @appointment = Appointment.find(params[:id])
    is_client = @appointment.client_id == current_user.id
    is_provider = @appointment.service.user_id == current_user.id

    unless is_client || is_provider
      redirect_to root_path, alert: "Agendamento não encontrado ou acesso negado."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Agendamento não encontrado."
  end

  def set_available_slots
    @available_slots = (8..18).flat_map { |hour| [format('%02d:00', hour), format('%02d:30', hour)] }
  end

  def set_busy_slots
    # REFATORAÇÃO DE PERFORMANCE:
    # Em vez de carregar TODOS os agendamentos do banco, carrega apenas os do serviço atual.
    # O @service já foi carregado no before_action :set_service

    # Se estivermos no método index, show ou dashboard, não precisamos calcular slots de um serviço específico
    return unless @service

    futuros = @service.appointments
                       .where.not(status: %i[cancelado reembolsado])
                       .where("start_time >= ?", Time.zone.now.beginning_of_day)

    @busy_slots = futuros.map do |app|
      app.start_time.in_time_zone.strftime("%Y-%m-%d %H:%M")
    end
  end

end
