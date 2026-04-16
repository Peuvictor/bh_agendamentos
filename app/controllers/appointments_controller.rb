class AppointmentsController < ApplicationController
  before_action :authenticate_user!

  # 1. Configurações baseadas na Rota Aninhada
  before_action :set_service, only: %i[new create]
  before_action :set_appointment, only: %i[show edit update destroy]

  # 2. Carrega os horários apenas quando formos renderizar a tela
  before_action :set_available_slots, only: %i[new create edit update]
  before_action :set_busy_slots, only: %i[new create edit update]

  def index
    # Roteamento inteligente: O que eu vejo depende de quem eu sou.
    if current_user.provider?
      @appointments = current_user.received_appointments.order(start_time: :asc)
    else
      @appointments = current_user.appointments.order(start_time: :asc)
    end
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
      AppointmentMailer.confirmation_email(@appointment).deliver_later
      redirect_to appointments_path, notice: "Agendamento realizado com sucesso no serviço #{@service.nome}!"
    else
      render :new, status: :unprocessable_entity
    end
  end
  def edit
  end

  def update
    if @appointment.update(appointment_params)
      redirect_to appointments_path, notice: "Agendamento atualizado com sucesso!", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # A sua lógica de guilhotina e backup para o Mailer está perfeita
    if @appointment.service.user_id == current_user.id || @appointment.client_id == current_user.id
      client_name = @appointment.client.nome
      client_email = @appointment.client.email
      service_name = @appointment.service.nome
      start_time = @appointment.start_time

      @appointment.destroy

      AppointmentMailer.cancellation_email(client_name, client_email, service_name, start_time).deliver_later
      redirect_back(fallback_location: root_path, notice: "Agendamento cancelado com sucesso. O horário já está livre!")
    else
      redirect_to root_path, alert: "Você não tem permissão para fazer isso."
    end
  end

  def dashboard
    # Painel exclusivo do prestador
    @my_appointments = Appointment.joins(:service)
                                  .where(services: { user_id: current_user.id })
                                  .where("start_time >= ?", Time.current.beginning_of_day)
                                  .order(start_time: :asc)
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

    futuros = @service.appointments.where("start_time >= ?", Time.zone.now.beginning_of_day)

    @busy_slots = futuros.map do |app|
      app.start_time.in_time_zone.strftime("%Y-%m-%d %H:%M")
    end
  end

  def appointment_params
    # O service_id não vem mais daqui, ele vem da URL aninhada (@service.appointments.build)
    params.require(:appointment).permit(:status)
  end
end
