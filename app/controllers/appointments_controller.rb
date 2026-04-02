class AppointmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_appointment, only: %i[ show edit update destroy ]
  before_action :set_services, only: %i[ new edit create update ]
  before_action :set_available_slots, only: %i[ new edit create update ]
  before_action :set_busy_slots, only: %i[ new edit create update ]
  def index
    @appointments = current_user.appointments_as_client.includes(:service).order(start_time: :asc)
  end

  def show
  end

  def new
    @appointment = current_user.appointments_as_client.build(service_id: params[:service_id])
  end

  def edit
  end

  def create
    @appointment = Appointment.new(appointment_params)
    @appointment.client_id = current_user.id

    # Juntando a Data (appointment_date) e a Hora (appointment_hour) no start_time
    if params[:appointment_date].present? && params[:appointment_hour].present?
      begin
        combined_time = Time.zone.parse("#{params[:appointment_date]} #{params[:appointment_hour]}")
        @appointment.start_time = combined_time
      rescue ArgumentError
        @appointment.errors.add(:start_time, "inválido. Verifique a data e hora.")
      end
    end

    if @appointment.save
      # GATILHO DO E-MAIL NA FILA (O jeito Sênior)
      AppointmentMailer.confirmation_email(@appointment).deliver_later

      redirect_to appointments_path, notice: "Agendamento realizado com sucesso!"
    else
      # O que faltava: Devolver o usuário para a tela se houver erro de validação
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @appointment.update(appointment_params)
      redirect_to appointments_path, notice: "Agendamento atualizado com sucesso!", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @appointment = Appointment.find(params[:id])

    if @appointment.service.user_id == current_user.id || @appointment.client_id == current_user.id

      # 1. SALVANDO OS DADOS ANTES DE DESTRUIR (Para o Sidekiq não se perder)
      client_name = @appointment.client.nome
      client_email = @appointment.client.email
      service_name = @appointment.service.nome
      start_time = @appointment.start_time

      # 2. A Guilhotina (Apaga do Banco)
      @appointment.destroy

      # 3. Dispara o E-mail de Cancelamento com os dados a salvo
      AppointmentMailer.cancellation_email(client_name, client_email, service_name, start_time).deliver_later

      redirect_back(fallback_location: root_path, notice: "Agendamento cancelado com sucesso. O horário já está livre!")
    else
      redirect_to root_path, alert: "Você não tem permissão para fazer isso."
    end
  end

  def dashboard
    authenticate_user!

    # Filtramos e ordenamos usando a coluna real do banco: start_time
    @my_appointments = Appointment.joins(:service)
                                  .where(services: { user_id: current_user.id })
                                  .where("start_time >= ?", Time.current.beginning_of_day)
                                  .order(start_time: :asc)
  end

  private

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

  def set_services
    @services = Service.order(:nome)
  end

  def set_available_slots
    @available_slots = (8..18).flat_map { |hour| [format('%02d:00', hour), format('%02d:30', hour)] }
  end
  def set_busy_slots
    @busy_slots = {}

    # 1. Pega os agendamentos futuros no banco de dados
    futuros = Appointment.includes(service: :user).where("start_time >= ?", Time.zone.now.beginning_of_day)

    # 2. Agrupa eles pelo ID do Prestador
    agendamentos_por_prestador = futuros.group_by { |a| a.service.user_id }

    # 3. Monta um mapa { ID_DO_SERVICO => ["2026-03-30 10:00", "2026-03-30 10:30"] }
    @services.each do |service|
      prestador_id = service.user_id
      agendamentos_dele = agendamentos_por_prestador[prestador_id] || []

    @busy_slots[service.id] = agendamentos_dele.map do |app|
        app.start_time.in_time_zone.strftime("%Y-%m-%d %H:%M")
      end
    end
  end

  def appointment_params
    params.require(:appointment).permit(:service_id, :status)
  end
end
