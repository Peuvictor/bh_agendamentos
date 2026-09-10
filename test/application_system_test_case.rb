require "test_helper"

# Match the accessible names used by screen readers and keyboard users.
Capybara.enable_aria_label = true

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  if ENV["SYSTEM_TEST_DRIVER"] == "selenium"
    require "selenium-webdriver"

    if ENV["CHROMEDRIVER_PATH"].present?
      Selenium::WebDriver::Chrome::Service.driver_path = ENV.fetch("CHROMEDRIVER_PATH")
    end

    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] do |options|
      options.binary = ENV.fetch("CHROME_BINARY") if ENV["CHROME_BINARY"].present?
      options.add_argument("--no-sandbox")
      options.add_argument("--disable-dev-shm-usage")
      # Browser password prompts can steal focus from the page after fixture logins.
      options.add_preference("credentials_enable_service", false)
      options.add_preference("profile.password_manager_enabled", false)
      options.add_preference("profile.password_manager_leak_detection", false)
    end
  else
    driven_by :rack_test
  end
end
