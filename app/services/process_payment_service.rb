class ProcessPaymentService
  # Expõe o erro (caso falhe) e o payload (para o PIX no frontend)
  attr_reader :error, :payload

  def initialize(appointment:, token:, payment_method_id:, issuer_id:, installments:)
    @appointment = appointment
    @token = token
    @payment_method_id = payment_method_id
    @issuer_id = issuer_id
    @installments = installments || 1 # Garante 1 parcela se for PIX
  end

  def call
    # 1. A FONTE DA VERDADE: Pega o preço direto do banco de dados
    amount = @appointment.service.preco

    require 'mercadopago'
    sdk = Mercadopago::SDK.new(ENV['MERCADO_PAGO_ACCESS_TOKEN'])

    # 2. CHAVE DE IDEMPOTÊNCIA: Previne dupla cobrança caso a rede oscile
    idempotency_key = SecureRandom.uuid

    payment_data = {
      transaction_amount: amount.to_f,
      token: @token,
      description: "Agendamento BH: #{@appointment.service.nome}",
      installments: @installments.to_i,
      payment_method_id: @payment_method_id,
      issuer_id: @issuer_id,
      payer: {
        email: @appointment.client.email
      }
    }

    # Injeta a chave de segurança no cabeçalho da requisição
    custom_headers = {
      'x-idempotency-key': idempotency_key
    }

    result = sdk.payment.create(payment_data, custom_headers)
    mp_response = result[:response]

    # O Mercado Pago retorna 'approved' para Cartão e 'pending' para PIX
    if %w[approved pending].include?(mp_response['status'])

      # 3. BLOCO DE TRANSAÇÃO: Ou salva tudo (Payment + Appointment) ou não salva nada
      ActiveRecord::Base.transaction do
        # Mapeia o status do MP para o nosso Enum do banco
        local_status = mp_response['status'] == 'approved' ? :aprovado : :pendente

        Payment.create!(
          appointment: @appointment,
          amount: amount,
          status: local_status,
          mp_transaction_id: mp_response['id'].to_s,
          idempotency_key: idempotency_key
        )

        # Só confirma o agendamento imediatamente se o cartão passar direto
        @appointment.update!(status: 'confirmado') if local_status == :aprovado
      end

      # 4. Guarda a resposta para o Controller devolver o QR Code do PIX ao frontend
      @payload = mp_response
      return true
    else
      @error = mp_response['status_detail'] || 'Pagamento recusado pela operadora.'
      return false
    end
  rescue StandardError => e
    # Captura quedas de API ou erros de banco e não deixa a aplicação quebrar
    @error = "Falha interna: #{e.message}"
    return false
  end
end
