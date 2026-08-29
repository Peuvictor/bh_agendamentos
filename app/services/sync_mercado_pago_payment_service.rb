class SyncMercadoPagoPaymentService
  InvalidGatewayPaymentError = MercadoPagoPaymentValidator::InvalidPaymentError

  attr_reader :payment, :remote_status, :result

  def initialize(payment_id:, gateway: nil)
    @payment_id = payment_id.to_s
    @gateway = gateway
  end

  def call
    @payment = Payment.includes(:appointment).find_by(mp_transaction_id: @payment_id)
    return finish(:not_found, success: false) unless @payment

    gateway_payment = gateway.fetch_payment(@payment_id)
    MercadoPagoPaymentValidator.validate!(gateway_payment, @payment)
    @remote_status = gateway_payment['status'].to_s

    transition = PaymentStateTransitionService.new(payment: @payment, gateway_payment: gateway_payment)
    transition.call
    finish(transition.result)
  end

  private

  def gateway
    @gateway ||= MercadoPagoPaymentGateway.new
  end

  def finish(value, success: true)
    @result = value
    success
  end
end
