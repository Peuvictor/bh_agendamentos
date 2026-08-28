class ProcessPaymentService
  class PaymentUnavailableError < StandardError; end

  ACCEPTED_GATEWAY_STATUSES = %w[approved pending in_process authorized].freeze

  attr_reader :error, :payload

  # The payment adapter remains injectable without changing the controller-facing keyword API.
  def initialize(appointment:, token:, payment_method_id:, issuer_id:, installments:, # rubocop:disable Metrics/ParameterLists
                 gateway: nil) # rubocop:enable Metrics/ParameterLists
    @appointment = appointment
    @token = token
    @payment_method_id = payment_method_id
    @issuer_id = issuer_id
    @installments = installments || 1
    @gateway = gateway
  end

  def call
    confirmed = false

    Appointment.transaction do
      @appointment.lock!
      validate_appointment!

      idempotency_key = SecureRandom.uuid
      expiration = Time.current + Rails.configuration.x.payment_expiration_minutes.minutes
      gateway_response = gateway.create_payment(
        payment_data(expiration),
        idempotency_key: idempotency_key
      )

      unless ACCEPTED_GATEWAY_STATUSES.include?(gateway_response['status'])
        @error = gateway_response['status_detail'].presence || 'Pagamento recusado pela operadora.'
        raise ActiveRecord::Rollback
      end

      payment = persist_payment!(gateway_response, idempotency_key, expiration)
      confirmed = payment.aprovado?
      @payload = gateway_response
    end

    return false unless @payload

    AppointmentMailer.confirmation_email(@appointment).deliver_later if confirmed
    true
  rescue PaymentUnavailableError => e
    @error = e.message
    false
  rescue StandardError => e
    Rails.logger.warn("Mercado Pago payment creation failed error=#{e.class}")
    @error = 'Não foi possível processar o pagamento agora. Tente novamente.'
    false
  end

  private

  def validate_appointment!
    unavailable = !@appointment.pendente? || @appointment.start_time <= Time.current ||
                  @appointment.expires_at.blank? || @appointment.expires_at <= Time.current

    raise PaymentUnavailableError, 'Este agendamento não está disponível para pagamento.' if unavailable
    return unless Payment.exists?(appointment_id: @appointment.id)

    raise PaymentUnavailableError, 'Já existe um pagamento para este agendamento.'
  end

  def payment_data(expiration)
    data = {
      transaction_amount: @appointment.service.preco.to_f,
      token: @token,
      description: "Agendamento BH: #{@appointment.service.nome}",
      installments: @installments.to_i,
      payment_method_id: @payment_method_id,
      issuer_id: @issuer_id,
      external_reference: @appointment.id.to_s,
      payer: { email: @appointment.client.email }
    }
    data[:date_of_expiration] = expiration.iso8601(3) if pix?
    data
  end

  def persist_payment!(gateway_response, idempotency_key, expiration)
    approved = gateway_response['status'] == 'approved'
    payment_expiration = if approved
                           nil
                         else
                           (pix? ? expiration : @appointment.expires_at)
                         end

    payment = Payment.create!(
      appointment: @appointment,
      amount: @appointment.service.preco,
      status: approved ? :aprovado : :pendente,
      mp_transaction_id: gateway_response.fetch('id').to_s,
      idempotency_key: idempotency_key,
      expires_at: payment_expiration
    )

    if approved
      @appointment.update!(status: :confirmado)
    elsif pix?
      @appointment.update!(expires_at: expiration)
    end

    payment
  end

  def pix?
    @payment_method_id == 'pix'
  end

  def gateway
    @gateway ||= MercadoPagoPaymentGateway.new
  end
end
