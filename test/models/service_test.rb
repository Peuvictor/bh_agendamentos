require "test_helper"

class ServiceTest < ActiveSupport::TestCase
  setup do
    @service = services(:one)
  end

  test "active and archived scopes are mutually exclusive" do
    @service.archive!

    assert_includes Service.archived, @service
    assert_not_includes Service.active, @service
    assert_includes Service.active, services(:two)
  end

  # rubocop:disable-next Minitest/MultipleAssertions
  test "archives and reactivates a service atomically" do
    @service.archive!

    assert_predicate @service, :archived?
    assert_not @service.archived_by_admin?

    @service.reactivate!

    assert_not_predicate @service, :archived?
    assert_not @service.archived_by_admin?
  end

  # rubocop:disable-next Minitest/MultipleAssertions
  test "an administrative archive takes precedence" do
    @service.archive!
    archived_at = @service.archived_at

    @service.archive!(by_admin: true)

    assert_equal archived_at, @service.archived_at
    assert_predicate @service, :archived_by_admin?
    assert_raises(ActiveRecord::RecordInvalid) { @service.reactivate! }

    @service.reactivate!(by_admin: true)

    assert_not_predicate @service, :archived?
  end

  # rubocop:disable-next Minitest/MultipleAssertions
  test "archiving preserves appointments payments reviews blocks and photo" do
    block = @service.user.availability_blocks.create!(
      service: @service,
      starts_at: 2.days.from_now,
      ends_at: 2.days.from_now + 1.hour
    )
    @service.photo.attach(io: StringIO.new("photo"), filename: "service.txt", content_type: "text/plain")
    counts = historical_counts

    preserved_models = [
      "Service.count", "Appointment.count", "Payment.count", "Review.count", "AvailabilityBlock.count"
    ]
    assert_no_difference(preserved_models) do
      @service.archive!
    end

    assert_equal counts, historical_counts
    assert AvailabilityBlock.exists?(block.id)
    assert_predicate @service.reload.photo, :attached?
  end

  private

  def historical_counts
    [
      @service.appointments.count,
      @service.reviews.count,
      Payment.where(appointment: @service.appointments).count
    ]
  end
end
