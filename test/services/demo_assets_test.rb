# frozen_string_literal: true

require 'test_helper'
require_relative '../support/demo_seed_helpers'

class DemoAssetsTest < ActiveSupport::TestCase
  include DemoSeedHelpers

  # rubocop:disable-next Minitest/MultipleAssertions
  test 'attaches versioned images once without replacing a user selected photo' do
    result = nil
    assert_difference('ActiveStorage::Attachment.count', 6) { result = seed_demo(images: true) }
    assert_empty result.missing_images
    provider = demo_record(User, 'user/provider')
    provider.avatar.attach(io: StringIO.new('custom photo'), filename: 'custom.png', content_type: 'image/png')
    blob_id = provider.avatar.blob.id

    assert_no_difference(['ActiveStorage::Attachment.count', 'ActiveStorage::Blob.count']) { seed_demo(images: true) }
    assert_equal blob_id, provider.reload.avatar.blob.id
  end

  # rubocop:disable-next Minitest/MultipleAssertions
  test 'upload failure preserves records reports filenames and can be retried' do
    result = nil
    ActiveStorage::Blob.service.stub(:upload, ->(*) { raise IOError, 'secret-provider-token' }) do
      result = seed_demo(images: true)
    end

    assert_equal 6, result.missing_images.size
    assert_not_includes result.missing_images.join, 'secret-provider-token'
    assert_predicate demo_record(Appointment, "#{result.week}/appointment/0"), :confirmado?
    snapshot = demo_snapshot(ignore_touch: true)

    assert_no_difference('ActiveStorage::Blob.count') { assert_empty seed_demo(images: true).missing_images }
    assert_equal snapshot, demo_snapshot(ignore_touch: true)
  end
end
