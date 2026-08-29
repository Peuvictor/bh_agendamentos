module AppointmentsHelper
  def appointment_status_label(appointment)
    return 'reembolsado' if appointment.reembolsado?
    return 'expirado por falta de pagamento' if appointment.expired_at?

    appointment.status
  end
end
