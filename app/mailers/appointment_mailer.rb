class AppointmentMailer < ApplicationMailer
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
end
