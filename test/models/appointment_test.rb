require "test_helper"

class AppointmentTest < ActiveSupport::TestCase
  test "a canceled appointment does not block the providers schedule" do
    canceled = Appointment.create!(
      client: users(:two),
      service: services(:one),
      start_time: 5.days.from_now.change(hour: 10, min: 0),
      status: :cancelado
    )

    replacement = Appointment.new(
      client: users(:two),
      service: services(:one),
      start_time: canceled.start_time
    )

    assert replacement.valid?
  end

  test "a refunded appointment does not block the providers schedule" do
    refunded = Appointment.create!(
      client: users(:two),
      service: services(:one),
      start_time: 6.days.from_now.change(hour: 10, min: 0),
      status: :reembolsado,
      refunded_at: Time.current
    )

    replacement = Appointment.new(
      client: users(:two),
      service: services(:one),
      start_time: refunded.start_time
    )

    assert_predicate replacement, :valid?
  end

  test "keeps existing enum values and appends refunded" do
    assert_equal(
      { "confirmado" => 0, "cancelado" => 1, "pendente" => 2, "reembolsado" => 4 },
      Appointment.statuses
    )
  end
end
