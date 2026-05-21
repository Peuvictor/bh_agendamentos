class PaymentsController < ApplicationController
  # Ignora a verificação de token CSRF apenas para essa requisição JS (o Token do MP já garante a segurança)
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    # O Brick do MP envia os dados aninhados ou diretos dependendo do método
    payment_data = payment_params

    result = ProcessPaymentService.call(payment_data)

    if result[:success]
      # Pagamento criado! Para PIX, o payload contém o QR Code e o Copia e Cola
      render json: { status: 'approved', detail: result[:payload] }, status: :created
    else
      render json: { status: 'rejected', error: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  # Permite exatamente os campos que o Checkout Bricks envia no formData
  def payment_params
    params.require(:payment).permit(
      :transaction_amount,
      :token,
      :description,
      :installments,
      :payment_method_id,
      :issuer_id,
      payer: [:email, identification: [:type, :number]]
    )
  end
end
