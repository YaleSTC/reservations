# frozen_string_literal: true
require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start
# Rspec should submit the result to CodeClimate automatically with each Travis
# CI build (repo token is encrypted in .travis.yml)

require 'rubygems'

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'capybara/rspec'
require 'capybara/rails'
# require 'rspec/autorun'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.infer_spec_type_from_file_location!
  # Needed in order to do integration tests with capybara
  config.include Capybara::DSL
  Capybara.asset_host = 'http://0.0.0.0:3000'
  Capybara.javascript_driver = :webkit

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = true

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  # DatabaseCleaner setup (2016-01-04 based on Rails Testing book)
  config.before(:suite) do
    DatabaseCleaner.clean_with(:deletion)
    ENV.delete('USE_LDAP')
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :deletion
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  # Remove when the last of the before(:all) blocks are removed
  config.after(:all) do
    DatabaseCleaner.clean_with(:truncation)
  end

  # set up app before all integration specs, wish we didn't have to use :each
  config.before(:each, type: :feature) { app_setup }

  # Devise helpers
  config.include Devise::TestHelpers, type: :controller
  config.include ControllerHelpers, type: :controller
  config.include EnvHelpers, type: :controller
  config.include Warden::Test::Helpers, type: :feature
  config.include InjectSession, type: :feature
  config.include FeatureHelpers, type: :feature
  config.include EnvHelpers, type: :feature
  config.include AppConfigHelpers
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
