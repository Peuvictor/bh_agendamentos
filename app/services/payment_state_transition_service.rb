# frozen_string_literal: true

class PaymentStateTransitionService
  class UnknownRemoteStatusError < StandardError; end
  class StateConflictError < StandardError; end

  Outcome = Data.define(:result, :appointment_confirmed, :appointment_expired)
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
    return approve_locked! if status == 'approved'
    return pending_outcome if PENDING_STATUSES.include?(status)

    payment_status = UNSUCCESSFUL_STATUSES[status]
    return finish_unsuccessful_locked!(payment_status, now: now) if payment_status

    raise UnknownRemoteStatusError, 'unknown Mercado Pago payment status'
  end

  def self.deliver_notifications(outcome, appointment)
    AppointmentMailer.confirmation_email(appointment).deliver_later if outcome.appointment_confirmed
    AppointmentMailer.expiration_email(appointment).deliver_later if outcome.appointment_expired
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
      appointment_expired: false
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
      appointment_expired: first_expiration
    )
  end

  def pending_outcome
    Outcome.new(result: :pending, appointment_confirmed: false, appointment_expired: false)
  end

  def approval_result(confirmed, already_processed)
    return :approved if confirmed
    return :already_processed if already_processed

    :approved_without_confirmation
  end

  def already_finished_outcome(payment_status)
    @payment.update!(status: payment_status) unless @payment.public_send("#{payment_status}?")
    Outcome.new(result: :already_finished, appointment_confirmed: false, appointment_expired: false)
  end

  def expire_records!(payment_status, now)
    @payment.update!(status: payment_status, expired_at: now)
    @appointment.update!(status: :cancelado, expired_at: now)
  end
end
