require "test_helper"

class AppointmentMailerTest < ActionMailer::TestCase
  test "builds a cancellation email from a persisted appointment" do
    appointment = appointments(:one)
    email = AppointmentMailer.cancellation_email(appointment)

    assert_equal [appointment.client.email], email.to
    assert_includes email.subject, appointment.service.nome
    assert_includes email.body.encoded, "cancelado com sucesso"
  end
end
