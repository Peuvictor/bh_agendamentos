# frozen_string_literal: true

require 'test_helper'

class AppointmentClientRoleTest < ActiveSupport::TestCase
  setup do
    @appointment = Appointment.new(client: users(:two), service: services(:one),
                                   start_time: 5.days.from_now.change(hour: 10, min: 0, sec: 0))
  end

  test 'persists an otherwise valid booking for a client' do
    assert_difference('Appointment.count', 1) { assert @appointment.save_for_active_service }
  end

  %i[provider admin].each do |role|
    test "does not persist an otherwise valid booking for a #{role}" do
      users(:one).update!(role: role)
      @appointment.client = users(:one)

      assert_no_difference('Appointment.count') { assert_not @appointment.save_for_active_service }
      assert_equal ['deve possuir perfil de cliente'], @appointment.errors[:client]
    end

    test "cannot replace the client of a persisted booking with a #{role}" do
      @appointment.save!
      users(:one).update!(role: role)

      assert_not @appointment.update(client_id: users(:one).id)
      assert_equal ['deve possuir perfil de cliente'], @appointment.errors[:client]
      assert_equal users(:two), @appointment.reload.client
    end
  end

  test 'does not persist a booking without a client' do
    @appointment.client = nil

    assert_no_difference('Appointment.count') { assert_not @appointment.save_for_active_service }
    assert_predicate @appointment.errors[:client], :any?
  end

  test 'allows cancellation of a legacy provider booking' do
    @appointment.save!
    users(:two).update!(role: :provider)

    assert_predicate @appointment.reload.client, :provider?
    assert @appointment.update(status: :cancelado)
    assert_predicate @appointment.reload, :cancelado?
  end

  test 'cannot duplicate a legacy provider booking into a new reservation' do
    duplicate = appointments(:one).dup
    duplicate.assign_attributes(start_time: @appointment.start_time, status: :pendente)

    assert_no_difference('Appointment.count') { assert_not duplicate.save_for_active_service }
    assert_equal ['deve possuir perfil de cliente'], duplicate.errors[:client]
  end
end
