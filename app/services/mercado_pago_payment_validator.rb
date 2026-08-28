# frozen_string_literal: true

class MercadoPagoPaymentValidator
  class InvalidPaymentError < StandardError; end

  def self.validate!(gateway_payment, payment)
    validate_id!(gateway_payment, payment)
    validate_amount!(gateway_payment, payment)
    validate_external_reference!(gateway_payment, payment)
    true
  rescue ArgumentError
    raise InvalidPaymentError, 'payment amount is invalid'
  end

  def self.validate_id!(gateway_payment, payment)
    return if gateway_payment['id'].to_s == payment.mp_transaction_id

    raise InvalidPaymentError, 'payment ID does not match the local payment'
  end

  def self.validate_amount!(gateway_payment, payment)
    return if BigDecimal(gateway_payment['transaction_amount'].to_s) == payment.amount

    raise InvalidPaymentError, 'payment amount does not match the appointment'
  end

  def self.validate_external_reference!(gateway_payment, payment)
    return if gateway_payment['external_reference'].to_s == payment.appointment_id.to_s

    raise InvalidPaymentError, 'external reference does not match the appointment'
  end

  private_class_method :validate_id!, :validate_amount!, :validate_external_reference!
end
