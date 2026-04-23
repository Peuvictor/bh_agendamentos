class ReviewsController < ApplicationController
  # 👇 Liberamos o 'index' para o público geral ver as avaliações
  before_action :authenticate_user!, except: [:index]

  def index
    @service = Service.find(params[:service_id])
    # Busca os reviews ordenados pelos mais recentes e carrega o cliente para não pesar o banco (N+1 query resolvido)
    @reviews = @service.reviews.includes(appointment: :client).order(created_at: :desc)
  end

  def create
    @appointment = Appointment.find(params[:appointment_id])

    if @appointment.client != current_user
      redirect_to root_path, alert: "Você não tem permissão para avaliar este agendamento, uai."
      return
    end

    unless @appointment.confirmado?
      redirect_to root_path, alert: "Você só pode avaliar serviços confirmados."
      return
    end

    @review = @appointment.build_review(review_params)

    if @review.save
      redirect_to authenticated_root_path, notice: "Obrigado pela sua avaliação! ⭐"
    else
      redirect_to authenticated_root_path, alert: "Erro ao enviar avaliação: #{@review.errors.full_messages.to_sentence}"
    end
  end

  private

  def review_params
    params.require(:review).permit(:rating, :comment)
  end
end
