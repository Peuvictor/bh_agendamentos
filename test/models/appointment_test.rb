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
end
