require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  if ENV["SYSTEM_TEST_DRIVER"] == "selenium"
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  else
    driven_by :rack_test
  end
end
