class AppointmentsController < ApplicationController
  # Garante que só quem está logado acessa essas páginas
  before_action :authenticate_user!
  before_action :set_appointment, only: %i[ show edit update destroy ]
  # Carrega os serviços para os selects das telas de new/edit
  before_action :set_services, only: %i[ new edit create update ]

  def index
    # Segurança: O usuário só vê os PRÓPRIOS agendamentos
    @appointments = current_user.appointments_as_client.includes(:service).order(start_time: :asc)
  end

  def show
    # Segurança extra: impede que alguém acesse /appointments/99 se o 99 não for dele
    redirect_to appointments_path, alert: "Acesso negado." unless @appointment.client == current_user
  end

  def new
    @appointment = current_user.appointments_as_client.build
  end

  def create
    # Vinculamos o agendamento ao usuário logado automaticamente
    @appointment = current_user.appointments_as_client.build(appointment_params)

    if @appointment.save
      redirect_to appointments_path, notice: "Agendamento realizado com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    # Forma Profissional: Apenas muda o status (Soft Delete)
    # @appointment.cancelado!

    # Forma Padrão: Apaga do banco
    @appointment.destroy

    respond_to do |format|
    # O status :see_other é vital para o Turbo no Rails 7
    format.html { redirect_to appointments_path, notice: "Agendamento cancelado com sucesso.", status: :see_other }
    format.json { head :no_content }
    end
  end

  # ... os métodos edit e  seguem a mesma lógica de segurança

  private

  def set_appointment
    # Buscamos apenas dentro dos agendamentos do usuário logado
    @appointment = current_user.appointments_as_client.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to appointments_path, alert: "Agendamento não encontrado."
  end

  def set_services
    @services = Service.all
  end

  def appointment_params
    # REMOVEMOS o :client_id daqui. O sistema define isso sozinho via current_user.
    params.require(:appointment).permit(:service_id, :start_time, :end_time, :status)
  end
end
