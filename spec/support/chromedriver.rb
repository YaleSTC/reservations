# frozen_string_literal: true

require 'selenium/webdriver'

Capybara.register_driver :selenium_chrome_headless_docker_friendly do |app|
  Capybara::Selenium::Driver.load_selenium
  browser_options = ::Selenium::WebDriver::Chrome::Options.new
  browser_options.args << '--headless'
  browser_options.args << '--disable-gpu'

  # Sandbox cannot be used inside unprivileged Docker container
  browser_options.args << '--no-sandbox'
  Capybara::Selenium::Driver
    .new(app, browser: :chrome, options: browser_options)
end

Capybara.javascript_driver = :selenium_chrome_headless_docker_friendly
