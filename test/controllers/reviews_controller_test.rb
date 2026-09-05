# frozen_string_literal: true

require 'test_helper'

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  test 'keeps old reviews accessible after service archiving' do
    service = services(:one)
    review = reviews(:one)
    service.archive!

    get service_reviews_url(service)

    assert_response :success
    assert_match review.comment, response.body
    assert_match service.nome, response.body
  end
end
