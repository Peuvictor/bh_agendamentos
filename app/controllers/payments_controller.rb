class PaymentsController < ApplicationController
  # 1. Autenticação obrigatória. A verificação CSRF volta a funcionar nativamente.
  before_action :authenticate_user!

  def create
    # 2. Segurança de posse: Garante que o agendamento pertence ao cliente logado
    @appointment = Appointment.where(client_id: current_user.id).find(params[:appointment_id])

    unless @appointment.pendente? && @appointment.start_time > Time.current
      return render json: { status: 'rejected', error: 'Este agendamento não está disponível para pagamento.' }, status: :unprocessable_content
    end

    # 3. Trava contra pagamento duplicado
    if @appointment.payment.present?
      message = @appointment.payment.aprovado? ? 'Este agendamento já foi pago.' : 'Já existe um pagamento em processamento para este agendamento.'
      return render json: { status: 'rejected', error: message }, status: :unprocessable_content
    end

    # 4. Chama o Service enviando APENAS os dados de tokenização
    service = ProcessPaymentService.new(
      appointment: @appointment,
      token: payment_params[:token],
      payment_method_id: payment_params[:payment_method_id],
      issuer_id: payment_params[:issuer_id],
      installments: payment_params[:installments]
    )

    if service.call
      # Manda a carga completa (payload) para o JS montar o PIX, se for o caso
      payload = service.payload
      render json: { status: payload['status'], detail: payload }, status: :created
    else
      render json: { status: 'rejected', error: service.error }, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotFound
    # 5. Captura erro caso o usuário tente forçar um ID que não é dele
    render json: { status: 'rejected', error: 'Agendamento inválido ou não pertence a você.' }, status: :not_found
  end

  private

  # 6. BLINDAGEM: :transaction_amount e :description foram EXPULSOS dos parâmetros permitidos.
  def payment_params
    params.require(:payment).permit(
      :token,
      :installments,
      :payment_method_id,
      :issuer_id,
      payer: [:email, identification: [:type, :number]]
    )
  end
end
