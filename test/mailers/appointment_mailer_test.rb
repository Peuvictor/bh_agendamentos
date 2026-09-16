require "test_helper"

class AppointmentMailerTest < ActionMailer::TestCase
  test "uses the configured sender" do
    previous_sender = ENV.fetch("MAILER_FROM", nil)
    ENV["MAILER_FROM"] = "sandbox@example.com"

    assert_equal ["sandbox@example.com"], AppointmentMailer.confirmation_email(appointments(:one)).from
  ensure
    ENV["MAILER_FROM"] = previous_sender
  end

  test "builds a cancellation email from a persisted appointment" do
    appointment = appointments(:one)
    email = AppointmentMailer.cancellation_email(appointment)

    assert_equal [appointment.client.email], email.to
    assert_includes email.subject, appointment.service.nome
    assert_includes email.body.encoded, "cancelado com sucesso"
  end

  test "explains that an expired appointment released the slot" do
    appointment = appointments(:one)
    email = AppointmentMailer.expiration_email(appointment)

    assert_equal [appointment.client.email], email.to
    assert_includes email.subject, "Prazo de pagamento expirado"
    assert_includes email.body.encoded, "horário foi liberado"
  end

  test "explains that a refunded appointment is inactive and its slot was released" do
    appointment = appointments(:one)
    email = AppointmentMailer.refund_email(appointment)

    assert_equal [appointment.client.email], email.to
    assert_includes email.subject, "Pagamento reembolsado"
    assert_match(/reserva não está mais ativa.*horário foi liberado/m, email.body.encoded)
  end

  # rubocop:disable-next Minitest/MultipleAssertions
  test "builds a reminder with the appointment details" do
    appointment = Appointment.create!(
      client: users(:two), service: services(:one),
      start_time: 7.days.from_now.change(hour: 10, min: 0), status: :confirmado
    )
    email = AppointmentMailer.reminder_email(appointment)

    assert_equal [appointment.client.email], email.to
    assert_includes email.subject, appointment.service.nome
    assert_includes email.body.encoded, appointment.service.user.nome
    assert_includes email.body.encoded, appointment.start_time.strftime('%H:%M')
    assert_includes email.body.encoded, "/appointments/#{appointment.id}"
  end
end
