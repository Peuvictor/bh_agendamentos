# frozen_string_literal: true

# rubocop:disable-next Metrics/ClassLength
class PaymentStateTransitionService
  class UnknownRemoteStatusError < StandardError; end
  class StateConflictError < StandardError; end

  Outcome = Data.define(:result, :appointment_confirmed, :appointment_expired, :appointment_refunded)
  PENDING_STATUSES = %w[pending in_process authorized].freeze
  UNSUCCESSFUL_STATUSES = { 'cancelled' => :cancelado, 'rejected' => :rejeitado }.freeze

  attr_reader :result

  def initialize(payment:, gateway_payment:)
    @payment = payment
    @appointment = payment.appointment
    @gateway_payment = gateway_payment
  end

  def call
    outcome = nil

    Appointment.transaction do
      @appointment.lock!
      @payment.lock!
      outcome = apply_locked!
    end

    self.class.deliver_notifications(outcome, @appointment)
    @result = outcome.result
    true
  end

  def apply_locked!(now: Time.current)
    status = @gateway_payment['status']
    return already_refunded_outcome(now: now) if refunded_locally?
    return refund_locked!(now: now) if status == 'refunded'
    return approve_locked! if status == 'approved'
    return pending_outcome if PENDING_STATUSES.include?(status)

    payment_status = UNSUCCESSFUL_STATUSES[status]
    return finish_unsuccessful_locked!(payment_status, now: now) if payment_status

    raise UnknownRemoteStatusError, 'unknown Mercado Pago payment status'
  end

  def self.deliver_notifications(outcome, appointment)
    AppointmentMailer.confirmation_email(appointment).deliver_later if outcome.appointment_confirmed
    AppointmentMailer.expiration_email(appointment).deliver_later if outcome.appointment_expired
    AppointmentMailer.refund_email(appointment).deliver_later if outcome.appointment_refunded
  end

  private

  def approve_locked!
    already_processed = @payment.aprovado?
    @payment.update!(status: :aprovado) unless already_processed

    confirmed = @appointment.pendente?
    @appointment.update!(status: :confirmado) if confirmed

    Outcome.new(
      result: approval_result(confirmed, already_processed),
      appointment_confirmed: confirmed,
      appointment_expired: false,
      appointment_refunded: false
    )
  end

  def finish_unsuccessful_locked!(payment_status, now:)
    raise StateConflictError, 'confirmed appointment has an unsuccessful remote payment' if @appointment.confirmado?
    return already_finished_outcome(payment_status) unless @appointment.pendente?

    first_expiration = @appointment.expired_at.nil?
    expire_records!(payment_status, now)

    Outcome.new(
      result: payment_status == :rejeitado ? :rejected : :cancelled,
      appointment_confirmed: false,
      appointment_expired: first_expiration,
      appointment_refunded: false
    )
  end

  def pending_outcome
    Outcome.new(
      result: :pending,
      appointment_confirmed: false,
      appointment_expired: false,
      appointment_refunded: false
    )
  end

  def approval_result(confirmed, already_processed)
    return :approved if confirmed
    return :already_processed if already_processed

    :approved_without_confirmation
  end

  def already_finished_outcome(payment_status)
    @payment.update!(status: payment_status) unless @payment.public_send("#{payment_status}?")
    Outcome.new(
      result: :already_finished,
      appointment_confirmed: false,
      appointment_expired: false,
      appointment_refunded: false
    )
  end

  def refund_locked!(now:)
    first_refund = @payment.refunded_at.nil? && @appointment.refunded_at.nil?

    @payment.update!(status: :reembolsado, refunded_at: @payment.refunded_at || now)
    @appointment.update!(status: :reembolsado, refunded_at: @appointment.refunded_at || now)

    Outcome.new(
      result: first_refund ? :refunded : :already_refunded,
      appointment_confirmed: false,
      appointment_expired: false,
      appointment_refunded: first_refund
    )
  end

  def refunded_locally?
    @payment.reembolsado? || @appointment.reembolsado?
  end

  def already_refunded_outcome(now:)
    ensure_refund_invariants!(now)

    Outcome.new(
      result: :already_refunded,
      appointment_confirmed: false,
      appointment_expired: false,
      appointment_refunded: false
    )
  end

  def ensure_refund_invariants!(now)
    refunded_at = @payment.refunded_at || @appointment.refunded_at || now
    payment_refunded = @payment.reembolsado? && @payment.refunded_at?
    appointment_refunded = @appointment.reembolsado? && @appointment.refunded_at?

    @payment.update!(status: :reembolsado, refunded_at: refunded_at) unless payment_refunded
    @appointment.update!(status: :reembolsado, refunded_at: refunded_at) unless appointment_refunded
  end

  def expire_records!(payment_status, now)
    @payment.update!(status: payment_status, expired_at: now)
    @appointment.update!(status: :cancelado, expired_at: now)
  end
end
