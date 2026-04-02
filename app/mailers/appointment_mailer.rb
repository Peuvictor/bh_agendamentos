class AppointmentMailer < ApplicationMailer
  # O default from geralmente fica no ApplicationMailer, mas pode colocar aqui também
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
end
