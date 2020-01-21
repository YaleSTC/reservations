source 'https://rubygems.org'

ruby '2.6.5' # Version in .ruby-version must match

# standard gems
gem 'rails', '~> 6.0.0'
gem 'mysql2', '~> 0.5.2'
gem 'rake', '~> 12.0.0'
gem 'jbuilder', '~> 2.9.1'

# gems required for the rails 5 update
gem 'responders', '~> 3.0.0'
gem 'record_tag_helper', '~> 1.0.0', :git => 'https://github.com/rails/record_tag_helper.git', :ref => '128cc1a577f97069b6f7826e06c07b65650529f2'
gem 'rails-controller-testing', '~> 1.0.3'
gem 'activemodel-serializers-xml', '~> 1.0.1'

# simulate environment variables
gem 'dotenv-rails', '~> 2.7.5', :require => 'dotenv/rails-now'

# authentication / authorization
gem 'devise', '~> 4.7.1'
gem 'devise_cas_authenticatable', '~> 1.10.0'
gem 'cancancan', '~> 2.0.0'

# scheduling
gem 'whenever', '~> 0.9.7'

# administrative panel
gem 'rails_admin', '~> 2.0.0'

# ldap integration
gem 'net-ldap', '~> 0.16.0'

# attachments

# for exporting multiple files
gem 'rubyzip', '~> 1.3.0'

# soft deletion
gem 'nilify_blanks', '~> 1.2.1'

# ui
gem 'jquery-rails', '~> 4.3.1'
gem 'jquery-ui-rails', '~> 5.0.5'
gem 'jquery-datatables-rails', '~> 3.4.0'
gem 'fullcalendar-rails', '~> 3.0.0.0'
gem 'momentjs-rails', '~> 2.17.1'
gem 'rails4-autocomplete', '~> 1.1.1'
# possibly replace above with rails-jquery-autocomplete v 1.0.3
gem 'select2-rails', '~> 4.0.3'
gem 'kaminari', '~> 0.17.0'
gem 'draper', '~> 3.1.0'
gem 'inline_svg', '~> 1.2.1'

# forms / formatting
gem 'simple_form', '~> 5.0.1'
gem 'cocoon', '~> 1.2.10'
gem 'redcarpet', '~> 3.4.0'

# iCalendar export
gem 'icalendar', '~> 2.4.1'

# bootsnap
gem "bootsnap", "~> 1.4"

# ActiveStorage
gem "mini_magick", "~> 4.9"
gem "active_storage_validations", "~> 0.8.4"
gem 'aws-sdk-s3', '~> 1'

group :development, :test do
  gem "bundler-audit", "~> 0.6.1"
  gem 'pry', '~> 0.10.4'
  gem 'pry-rails', '~> 0.3.6'
  gem 'pry-byebug', '~> 3.4.2'
  gem 'pry-stack_explorer', '~> 0.4.9.2'
  gem 'pry-remote', '~> 0.1.8'
  gem 'letter_opener', '~> 1.4.1'
  gem 'letter_opener_web', '~> 1.3.0'
  gem 'factory_girl_rails', '~> 4.7.0'
  gem 'rspec-rails', '~> 4.0.0.beta2'
  gem 'shoulda-matchers', '~> 3.1.3'
  gem 'capybara', '~> 3.9.0'
  gem 'capybara-selenium', '~> 0.0.6'
  gem 'selenium-webdriver', '~> 3.14.1'
  gem "puma", "~> 4.1"
  gem 'spring', '~> 2.0.2'
  gem 'spring-commands-rspec', '~> 1.0.4'
  gem 'fuubar', '~> 2.2.0'
  gem 'guard-livereload', '~> 2.5.2'
  gem 'capistrano', '3.8.2', require: false
  gem 'capistrano-bundler', '~> 1.2.0', require: false
  gem 'capistrano-rails', '~> 1.3.0', require: false
  gem 'capistrano-rvm', '~> 0.1.2', require: false
  gem 'highline', '~> 1.7.8', require: false
  gem 'awesome_print', '~> 1.8.0'
  gem 'codeclimate-test-reporter', '~> 1.0.8'
  gem 'database_cleaner', '~> 1.6.1'
  gem 'rubocop', '~> 0.49.1', require: false
  gem 'timecop', '~> 0.9.1'
end

group :development, :test, :heroku do
  # seed script gems
  gem 'ffaker', '~> 2.6.0', require: false
  gem 'ruby-progressbar', '~> 1.8.1', require: false
end

# assets
gem 'sass-rails', '~> 5.0.6'
gem 'uglifier', '~> 3.2.0'
gem 'bootstrap-sass', '~> 3.4.1'
gem 'font-awesome-rails', '~> 4.7.0.5'

group :development do
  gem 'thin', '~> 1.7.0'
  gem 'rack-mini-profiler', '~> 1.1.0'
  gem 'bullet', '~> 6.0.2'
end

group :production do
  gem 'therubyracer', '~> 0.12.3', require: 'v8'
  gem 'party_foul', '~> 1.5.5'
end

group :heroku do
  gem 'unicorn', '~> 5.1.0'
  gem 'rack-timeout', '~> 0.4.2'
  gem 'aws-sdk', '~> 3'
  gem 'rails_12factor', '~> 0.0.3'
end
