# frozen_string_literal: true

require 'test_helper'
require_relative '../support/rescheduling_setup'

# rubocop:disable Minitest/MultipleAssertions
class AppointmentReschedulingMailerTest < ActionMailer::TestCase
  include ReschedulingSetup

  test 'notifies both participants and uses the historical interval after another change' do
    appointment = create_paid_appointment
    service = rescheduler(appointment)
    assert_enqueued_emails(2) { assert service.call }
    first = service.rescheduling

    assert rescheduler(appointment, hour: '16:00').call

    mail = AppointmentMailer.rescheduling_email(first, users(:one))

    assert_equal [users(:one).email], mail.to
    assert_match '14:00', mail.text_part.body.decoded
    assert_no_match '16:00', mail.text_part.body.decoded
    assert_match users(:two).nome, mail.html_part.body.decoded
  end

  test 'does not enqueue notifications when the surrounding transaction rolls back' do
    appointment = create_paid_appointment
    assert_no_enqueued_emails do
      Appointment.transaction(requires_new: true) do
        assert rescheduler(appointment).call
        raise ActiveRecord::Rollback
      end
    end
    assert_empty appointment.reschedulings.reload
  end

  test 'deduplicates recipient email addresses' do
    appointment = create_paid_appointment
    appointment.update!(client: users(:one))

    assert_enqueued_emails(1) { assert rescheduler(appointment, actor: users(:one)).call }
  end
end

# rubocop:enable Minitest/MultipleAssertions
