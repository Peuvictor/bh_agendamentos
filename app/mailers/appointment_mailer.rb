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

  def cancellation_email(client_name, client_email, service_name, start_time)
    # Recebemos os textos puros e guardamos nas variáveis da View
    @client_name = client_name
    @service_name = service_name
    @start_time = start_time

    mail(
      to: client_email,
      subject: "❌ Agendamento Cancelado: #{@service_name}"
    )
  end
end
