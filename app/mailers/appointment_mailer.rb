class AppointmentMailer < ApplicationMailer
  default from: 'nao-responda@agendabh.com.br'

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
end
