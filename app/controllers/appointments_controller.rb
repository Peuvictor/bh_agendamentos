class AppointmentsController < ApplicationController
  # Garante que só quem está logado acessa essas páginas
  before_action :authenticate_user!

  # Filtros de segurança e carregamento de dados
  before_action :set_appointment, only: %i[ show edit update destroy ]
  before_action :set_services, only: %i[ new edit create update ]

  def index
    # Segurança: O usuário só vê os PRÓPRIOS agendamentos
    # Usamos .includes(:service) para evitar o problema de N+1 queries
    @appointments = current_user.appointments_as_client.includes(:service).order(start_time: :asc)
  end

  def show
    # O set_appointment já garantiu que o agendamento pertence ao current_user
  end

  def new
    @appointment = current_user.appointments_as_client.build
  end

  def edit
    # O set_appointment já buscou o agendamento no banco para nós
  end

  def create
    @appointment = current_user.appointments_as_client.build(appointment_params)

    if @appointment.save
      redirect_to appointments_path, notice: "Agendamento realizado com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @appointment.update(appointment_params)
      # status: :see_other é importante para o Turbo do Rails 7 em redirecionamentos após PATCH
      redirect_to appointments_path, notice: "Agendamento atualizado com sucesso!", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @appointment.destroy

    respond_to do |format|
      format.html { redirect_to appointments_path, notice: "Agendamento cancelado com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_appointment
    # Segurança Máxima: Buscamos apenas nos agendamentos QUE PERTENCEM ao usuário logado
    # Se alguém tentar acessar o ID de outra pessoa, o Rails lança RecordNotFound
    @appointment = current_user.appointments_as_client.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to appointments_path, alert: "Agendamento não encontrado ou acesso negado."
  end

  def set_services
    @services = Service.all
  end

  def appointment_params
    # Proteção de Strong Parameters: client_id é definido pelo sistema, não pelo usuário
    params.require(:appointment).permit(:service_id, :start_time, :end_time, :status)
  end
end
