require "mercadopago"

class SyncMercadoPagoPaymentService
  class InvalidGatewayPaymentError < StandardError; end

  attr_reader :result

  def initialize(payment_id:)
    @payment_id = payment_id.to_s
  end

  def call
    payment = Payment.includes(:appointment).find_by(mp_transaction_id: @payment_id)
    return finish(:not_found, success: false) unless payment

    gateway_payment = fetch_gateway_payment
    validate_gateway_payment!(gateway_payment, payment)

    case gateway_payment["status"]
    when "approved"
      approve(payment)
    when "pending", "in_process", "authorized"
      finish(:pending)
    else
      finish(:ignored)
    end
  end

  private

  def fetch_gateway_payment
    sdk = Mercadopago::SDK.new(ENV["MERCADO_PAGO_ACCESS_TOKEN"])
    response = sdk.payment.get(@payment_id)

    unless response[:status].to_i.between?(200, 299) && response[:response].is_a?(Hash)
      raise InvalidGatewayPaymentError, "Mercado Pago returned HTTP #{response[:status]}"
    end

    response[:response]
  end

  def validate_gateway_payment!(gateway_payment, payment)
    unless gateway_payment["id"].to_s == @payment_id
      raise InvalidGatewayPaymentError, "payment ID does not match the notification"
    end

    unless BigDecimal(gateway_payment["transaction_amount"].to_s) == payment.amount
      raise InvalidGatewayPaymentError, "payment amount does not match the appointment"
    end

    external_reference = gateway_payment["external_reference"].to_s
    return if external_reference.blank? || external_reference == payment.appointment_id.to_s

    raise InvalidGatewayPaymentError, "external reference does not match the appointment"
  rescue ArgumentError
    raise InvalidGatewayPaymentError, "payment amount is invalid"
  end

  def approve(payment)
    confirmation_required = false
    already_processed = false

    Payment.transaction do
      payment.lock!
      appointment = payment.appointment
      appointment.lock!

      already_processed = payment.aprovado?
      payment.update!(status: :aprovado) unless payment.aprovado?

      if appointment.pendente?
        appointment.update!(status: :confirmado)
        confirmation_required = true
      end
    end

    AppointmentMailer.confirmation_email(payment.appointment).deliver_later if confirmation_required
    result = if confirmation_required
      :approved
    elsif already_processed
      :already_processed
    else
      :approved_without_confirmation
    end

    finish(result)
  end

  def finish(value, success: true)
    @result = value
    success
  end
end
