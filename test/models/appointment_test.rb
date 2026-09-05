require "test_helper"

class AppointmentTest < ActiveSupport::TestCase
  test "rejects a new appointment for an archived service" do
    service = services(:one)
    service.archive!
    appointment = Appointment.new(
      client: users(:two),
      service: service,
      start_time: 5.days.from_now.change(hour: 10, min: 0)
    )

    assert_not appointment.valid?
    assert_includes appointment.errors[:service], "está arquivado e não aceita novas reservas"
    assert_not appointment.save
  end

  test "rechecks the service under lock immediately before insertion" do
    service = Service.find(services(:one).id)
    appointment = Appointment.new(
      client: users(:two),
      service: service,
      start_time: 5.days.from_now.change(hour: 10, min: 0)
    )

    assert_predicate appointment, :valid?
    Service.find(service.id).archive!

    assert_no_difference("Appointment.count") do
      assert_not appointment.save_for_active_service
    end
  end

  test "allows status changes to an existing appointment after archiving" do
    appointment = Appointment.create!(
      client: users(:two),
      service: services(:one),
      start_time: 5.days.from_now.change(hour: 10, min: 0)
    )
    appointment.service.archive!

    assert appointment.update(status: :cancelado)
  end

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

  test "rejects a time blocked for every provider service" do
    date = 5.days.from_now.to_date
    provider = services(:one).user
    start_time = Time.zone.local(date.year, date.month, date.day, 10)
    provider.availability_blocks.create!(
      starts_at: start_time,
      ends_at: start_time + 1.hour,
      reason: "Loja fechada"
    )

    appointment = Appointment.new(client: users(:two), service: services(:one), start_time: start_time)

    assert_not appointment.valid?
    assert_includes appointment.errors[:start_time], "não está disponível na agenda do prestador"
  end

  test "rejects a time outside the providers slot intervals" do
    start_time = 5.days.from_now.change(hour: 10, min: 15, sec: 0)
    appointment = Appointment.new(client: users(:two), service: services(:one), start_time: start_time)

    assert_not appointment.valid?
    assert_includes appointment.errors[:start_time], "não está disponível na agenda do prestador"
  end
end
