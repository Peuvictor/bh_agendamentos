# frozen_string_literal: true

class ExpireAppointmentService
  class CancellationNotConfirmedError < StandardError; end

  CANCELLABLE_STATUSES = %w[pending in_process authorized].freeze

  attr_reader :result, :remote_status, :payment_id

  def initialize(appointment_id:, gateway: MercadoPagoPaymentGateway.new)
    @appointment_id = appointment_id
    @gateway = gateway
  end

  def call
    appointment, outcome = expire_candidate
    return record_result(outcome) if outcome.is_a?(Symbol)

    PaymentStateTransitionService.deliver_notifications(outcome, appointment)
    record_result(outcome.result)
  end

  private

  def due?(appointment)
    appointment.pendente? && appointment.expires_at.present? && appointment.expires_at <= Time.current
  end

  def expire_candidate
    Appointment.transaction do
      appointment = Appointment.find_by(id: @appointment_id)
      next [nil, :not_found] unless appointment

      appointment.lock!
      next [appointment, :not_due] unless due?(appointment)

      [appointment, expire_locked!(appointment)]
    end
  end

  def expire_locked!(appointment)
    payment = Payment.find_by(appointment_id: appointment.id)
    return expire_without_payment_locked!(appointment) unless payment

    payment.lock!
    @payment_id = payment.mp_transaction_id
    reconcile_payment_locked!(payment)
  end

  def reconcile_payment_locked!(payment)
    gateway_payment = @gateway.fetch_payment(payment.mp_transaction_id)
    validate!(gateway_payment, payment)
    @remote_status = gateway_payment['status']

    return apply_locked(payment, gateway_payment) unless CANCELLABLE_STATUSES.include?(@remote_status)

    cancel_and_reconcile_locked!(payment)
  end

  def cancel_and_reconcile_locked!(payment)
    cancellation = @gateway.cancel_payment(payment.mp_transaction_id)
    validate!(cancellation, payment)
    @remote_status = cancellation['status']

    unless %w[approved cancelled rejected].include?(@remote_status)
      raise CancellationNotConfirmedError, 'Mercado Pago cancellation was not confirmed'
    end

    apply_locked(payment, cancellation)
  rescue StandardError => e
    reconcile_after_cancellation_error_locked!(payment, e)
  end

  def reconcile_after_cancellation_error_locked!(payment, cancellation_error)
    gateway_payment = @gateway.fetch_payment(payment.mp_transaction_id)
    validate!(gateway_payment, payment)
    @remote_status = gateway_payment['status']

    raise cancellation_error unless %w[approved cancelled rejected].include?(@remote_status)

    apply_locked(payment, gateway_payment)
  end

  def validate!(gateway_payment, payment)
    MercadoPagoPaymentValidator.validate!(gateway_payment, payment)
  end

  def apply_locked(payment, gateway_payment)
    PaymentStateTransitionService.new(
      payment: payment,
      gateway_payment: gateway_payment
    ).apply_locked!
  end

  def expire_without_payment_locked!(appointment)
    first_expiration = appointment.expired_at.nil?
    now = Time.current
    appointment.update!(status: :cancelado, expired_at: appointment.expired_at || now)

    PaymentStateTransitionService::Outcome.new(
      result: :expired_without_payment,
      appointment_confirmed: false,
      appointment_expired: first_expiration
    )
  end

  def record_result(value)
    @result = value
  end
end
