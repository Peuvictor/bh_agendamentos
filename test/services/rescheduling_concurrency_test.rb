# frozen_string_literal: true

require 'test_helper'
require 'timeout'
require_relative '../support/rescheduling_setup'
require_relative '../support/database_concurrency_helpers'

class ReschedulingConcurrencyTest < ActiveSupport::TestCase
  include ReschedulingSetup
  include ActiveJob::TestHelper
  include DatabaseConcurrencyHelpers

  self.use_transactional_tests = false

  setup do
    @appointments = [create_paid_appointment(hour: 10), create_paid_appointment(hour: 11)]
  end

  teardown do
    ids = Appointment.where.not(id: [appointments(:one).id, appointments(:two).id]).pluck(:id)
    AppointmentRescheduling.where(appointment_id: ids).delete_all
    Payment.where(appointment_id: ids).delete_all
    Appointment.where(id: ids).delete_all
    @extra_provider&.destroy!
    clear_enqueued_jobs
  end

  test 'two bookings competing for one slot have exactly one winner' do
    results = compete(*@appointments.map do |appointment|
      -> { rescheduler(Appointment.find(appointment.id)).call }
    end)

    assert_equal [false, true], results.sort_by(&:to_s)
    assert_equal 1, AppointmentRescheduling.count
    assert_equal 1, Appointment.where(start_time: @appointments.first.start_time.change(hour: 14)).count
  end

  test 'creation and rescheduling across services cannot reserve the same slot' do
    second_service = services(:two)
    second_service.update!(user: users(:one))
    start = @appointments.first.start_time.change(hour: 14)
    results = compete(
      -> { rescheduler(Appointment.find(@appointments.first.id)).call },
      lambda {
        Appointment.new(service: Service.find(second_service.id), client: users(:two), start_time: start)
                   .save_for_active_service
      }
    )

    assert_equal [false, true], results.sort_by(&:to_s)
    assert_equal 1, Appointment.where(start_time: start).count
  ensure
    second_service&.update!(user: users(:two))
  end

  test 'two forms for the same booking cannot overwrite each other' do
    appointment = @appointments.first
    token = appointment.schedule_token
    results = compete(*%w[14:00 15:00].map do |hour|
      -> { rescheduler(Appointment.find(appointment.id), hour: hour, token: token).call }
    end)

    assert_equal [false, true], results.sort_by(&:to_s)
    assert_equal 1, appointment.reschedulings.count
  end

  # Keep the barrier at history insertion to exercise PostgreSQL foreign key locks.
  test 'providers booking each other can reschedule concurrently without foreign key deadlocks' do
    @extra_provider = User.create!(nome: 'Outro prestador', email: 'mutual@example.com',
                                   password: 'password123', role: :provider)
    extra_service = @extra_provider.services.create!(nome: 'Serviço adicional', duration: 30, preco: 10)
    first = @appointments.first
    first.update!(client: @extra_provider)
    second = create_paid_appointment(service: extra_service)
    second.update!(client: users(:one))
    histories_ready = Queue.new
    release_histories = Queue.new
    operations = [first, second].map do |appointment|
      lambda {
        service = rescheduler(Appointment.find(appointment.id), actor: appointment.client)
        persist = service.method(:record_change!)
        service.stub(:record_change!, lambda { |previous|
          histories_ready << true
          release_histories.pop
          persist.call(previous)
        }) { service.call }
      }
    end
    results = compete(*operations) do
      Timeout.timeout(10) { 2.times { histories_ready.pop } }
      2.times { release_histories << true }
    end

    assert_equal [true, true], results
  end

  test 'a cancellation committed while rescheduling waits prevents the move' do
    assert_terminal_transition_wins do |appointment|
      appointment.update!(status: :cancelado)
    end
  end

  test 'a refund committed while rescheduling waits prevents the move' do
    assert_terminal_transition_wins do |appointment|
      payment = appointment.payment
      payment.lock!
      PaymentStateTransitionService.new(payment: payment, gateway_payment: { 'status' => 'refunded' }).apply_locked!
    end
  end
end
