class AppointmentMailer < ApplicationMailer
  def rescheduling_email(rescheduling, recipient)
    @rescheduling = rescheduling
    @appointment = rescheduling.appointment
    @service = @appointment.service
    mail(to: recipient.email, subject: "Agendamento reagendado: #{@service.nome}")
  end

  def confirmation_email(appointment)
    @appointment = appointment
    @client = appointment.client
    @service = appointment.service

    mail(
      to: @client.email,
      subject: "✅ Agendamento Confirmado: #{@service.nome}"
    )
  end

  def cancellation_email(appointment)
    # Agora recebemos o objeto inteiro, pois ele não foi apagado do banco!
    @appointment = appointment
    @client = appointment.client
    @service = appointment.service

    mail(
      to: @client.email,
      subject: "❌ Agendamento Cancelado: #{@service.nome}"
    )
  end

  def expiration_email(appointment)
    @appointment = appointment
    @client = appointment.client
    @service = appointment.service

    mail(
      to: @client.email,
      subject: "Prazo de pagamento expirado: #{@service.nome}"
    )
  end

  def refund_email(appointment)
    @appointment = appointment
    @client = appointment.client
    @service = appointment.service

    mail(
      to: @client.email,
      subject: "Pagamento reembolsado: #{@service.nome}"
    )
  end

  def reminder_email(appointment)
    @appointment = appointment
    @client = appointment.client
    @service = appointment.service
    @provider = @service.user

    mail(
      to: @client.email,
      subject: "Lembrete de atendimento: #{@service.nome}"
    )
  end
end
