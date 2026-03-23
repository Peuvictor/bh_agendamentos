class AppointmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_appointment, only: %i[ show edit update destroy ]
  before_action :set_services, only: %i[ new edit create update ]
  before_action :set_available_slots, only: %i[ new edit create update ]

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
    @appointment = current_user.appointments_as_client.build(appointment_params)

    # Juntando a Data (appointment_date) e a Hora (appointment_hour) no start_time
    if params[:appointment_date].present? && params[:appointment_hour].present?
      begin
        combined_time = "#{params[:appointment_date]} #{params[:appointment_hour]}".to_datetime
        @appointment.start_time = combined_time
      rescue ArgumentError
        @appointment.errors.add(:start_time, "inválido. Verifique a data e hora.")
      end
    end

    if @appointment.save
      redirect_to @appointment, notice: "Agendamento realizado com sucesso!"
    else
      # Se falhar, renderiza o formulário de novo com os erros
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
    @appointment.destroy
    redirect_to appointments_path, notice: "Agendamento cancelado com sucesso.", status: :see_other
  end

  private

  def set_appointment
    @appointment = current_user.appointments_as_client.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to appointments_path, alert: "Agendamento não encontrado ou acesso negado."
  end

  def set_services
    @services = Service.order(:nome)
  end

  def set_available_slots
    # Gera horários de 30 em 30 min (08h às 18h)
    @available_slots = (8..18).flat_map { |hour| ["#{hour}:00", "#{hour}:30"] }
  end

  def appointment_params
    # Permitimos apenas service_id e status.
    # O start_time é montado manualmente no create e o end_time no model.
    params.require(:appointment).permit(:service_id, :status)
  end
end
