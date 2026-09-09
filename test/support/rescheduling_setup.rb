# frozen_string_literal: true

module ReschedulingSetup
  def create_paid_appointment(service: services(:one), hour: 10)
    appointment = Appointment.create!(client: users(:two), service: service,
                                      start_time: 7.days.from_now.change(hour: hour, min: 0, sec: 0),
                                      status: :confirmado)
    Payment.create!(appointment: appointment, amount: service.preco, status: :aprovado,
                    mp_transaction_id: SecureRandom.uuid, idempotency_key: SecureRandom.uuid)
    appointment
  end

  def rescheduler(appointment, actor: users(:two), date: nil, hour: '14:00', token: nil)
    RescheduleAppointmentService.new(appointment: appointment, actor: actor,
                                     date: date || appointment.start_time.to_date.iso8601, hour: hour,
                                     schedule_token: token || appointment.schedule_token)
  end
end
