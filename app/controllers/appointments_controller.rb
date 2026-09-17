class AppointmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_client_role, only: %i[new create available_slots]

  # 1. Configurações baseadas na Rota Aninhada
  before_action :set_service, only: %i[new create available_slots]
  before_action :set_appointment, only: %i[show edit update destroy rescheduling_slots]

  # 2. Carrega os horários apenas quando formos renderizar a tela
  before_action :set_available_slots, only: %i[new create]

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

    if @appointment.save_for_active_service
      redirect_to appointment_path(@appointment), notice: "Horário reservado. Conclua o pagamento para confirmar o agendamento."
    elsif @service.reload.archived?
      redirect_to vitrine_path, alert: "Este serviço está arquivado e não aceita novas reservas."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def available_slots
    date = Date.iso8601(params.require(:date))
    slots = ProviderAvailability.new(service: @service, date: date).slots

    render json: { slots: slots }
  rescue ActionController::ParameterMissing, Date::Error
    render json: { slots: [], error: "Data inválida" }, status: :unprocessable_content
  end

  def edit
    return unavailable_rescheduling unless @appointment.reschedulable?

    load_rescheduling_form
  end

  def update
    return unavailable_rescheduling unless @appointment.reschedulable?

    updater = RescheduleAppointmentService.new(
      appointment: @appointment, actor: current_user,
      date: params[:appointment_date], hour: params[:appointment_hour], schedule_token: params[:schedule_token]
    )
    if updater.call
      redirect_to appointment_path(@appointment), notice: 'Agendamento reagendado com sucesso.', status: :see_other
    else
      @appointment.reload
      @rescheduling_error = updater.error
      @stale_schedule = updater.stale?
      load_rescheduling_form
      render :edit, status: updater.stale? ? :conflict : :unprocessable_content
    end
  end

  def rescheduling_slots
    unless @appointment.reschedulable?
      return render json: { slots: [], error: 'Este agendamento não está disponível para reagendamento.' },
                    status: :unprocessable_content
    end

    date = Date.iso8601(params.require(:date))
    render json: { slots: rescheduling_availability(date).slots }
  rescue ActionController::ParameterMissing, Date::Error
    render json: { slots: [], error: 'Data inválida' }, status: :unprocessable_content
  end

  def destroy
    @appointment.with_lock { cancel_locked }
  end

  def cancel_locked
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

    @appointment.with_lock { update_status_locked }
  end

  def update_status_locked
    # Trava de Segurança: Só o prestador dono do serviço pode alterar
    if @appointment.service.user == current_user
      if @appointment.cancelado? || @appointment.reembolsado? || @appointment.start_time <= Time.current
        return redirect_to dashboard_path, alert: 'Este agendamento não pode mais ser alterado.'
      end

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
  private :cancel_locked, :update_status_locked

  private

  def require_client_role
    return if current_user.client?

    message = "Apenas clientes podem agendar serviços."
    respond_to do |format|
      format.html { redirect_to vitrine_path, alert: message }
      format.json { render json: { error: message }, status: :forbidden }
    end
  end

  def unavailable_rescheduling
    redirect_to appointment_path(@appointment), alert: 'Este agendamento não está disponível para reagendamento.'
  end

  def load_rescheduling_form
    @selected_date = if params[:appointment_date].present?
                       selected_appointment_date
                     else
                       @appointment.start_time.to_date
                     end
    @available_slots = rescheduling_availability(@selected_date).slots
    @schedule_token = params[:schedule_token].presence || @appointment.schedule_token
  end

  def rescheduling_availability(date)
    ProviderAvailability.new(service: @appointment.service, date: date,
                             exclude_appointment: @appointment, duration: @appointment.reserved_duration)
  end

  # NOVO: Busca o serviço com base na URL aninhada (ex: /services/5/appointments/new)
  def set_service
    @service = Service.find(params[:service_id] || params[:id])
    return unless @service.archived?

    redirect_to vitrine_path, alert: "Este serviço está arquivado e não aceita novas reservas."
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
    @selected_date = selected_appointment_date
    @available_slots = ProviderAvailability.new(service: @service, date: @selected_date).slots
  end

  def selected_appointment_date
    return Date.current if params[:appointment_date].blank?

    Date.iso8601(params[:appointment_date])
  rescue Date::Error
    Date.current
  end

end
