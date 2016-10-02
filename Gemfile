source 'https://rubygems.org'

ruby '2.3.1' # Version in .ruby-version must match

# standard gems
gem 'rails', '~> 4.2.6'
gem 'mysql2', '~> 0.4.4'
gem 'rake', '~> 11.1.2'
gem 'jbuilder', '~> 2.4.0'

# simulate environment variables
gem 'dotenv-rails', '~> 2.1.1', :require => 'dotenv/rails-now'

# authentication / authorization
gem 'devise', '~> 4.1.1'
gem 'devise_cas_authenticatable', '~> 1.9.1'
gem 'cancancan', '~> 1.14.0'

# scheduling
gem 'whenever', '~> 0.9.4'

# administrative panel
gem 'rails_admin', '~> 0.8.1'

# ldap integration
gem 'net-ldap', '~> 0.14.0'

# attachments
gem 'paperclip', '~> 4.3.6'

# for exporting multiple files
gem 'rubyzip', '~> 1.2.0'

# soft deletion
gem 'permanent_records', '= 4.1.5'
gem 'nilify_blanks', '~> 1.2.1'

# ui
gem 'jquery-rails', '~> 4.1.1'
gem 'jquery-ui-rails', '~> 5.0.5'
gem 'jquery-datatables-rails', '~> 3.4.0'
gem 'fullcalendar-rails', '~> 2.6.1.0'
gem 'momentjs-rails', '~> 2.11.1'
gem 'rails4-autocomplete', '~> 1.1.1'
gem 'select2-rails', '~> 4.0.2'
gem 'kaminari', '~> 0.16.3'
gem 'draper', '~> 2.1.0'
gem 'inline_svg', '~> 0.8.0'

# forms / formatting
gem 'simple_form', '~> 3.2.1'
gem 'cocoon', '~> 1.2.9'
gem 'redcarpet', '~> 3.3.4'

# iCalendar export
gem 'icalendar', '~> 2.3.0'

group :development, :test do
  gem 'pry', '~> 0.10.3'
  gem 'pry-rails', '~> 0.3.4'
  gem 'pry-byebug', '~> 3.4.0'
  gem 'pry-stack_explorer', '~> 0.4.9.2'
  gem 'pry-remote', '~> 0.1.8'
  gem 'letter_opener', '~> 1.4.1'
  gem 'letter_opener_web', '~> 1.3.0'
  gem 'factory_girl_rails', '~> 4.7.0'
  gem 'rspec-rails', '~> 3.4.2'
  gem 'shoulda-matchers', '~> 3.1.1'
  gem 'capybara', '~> 2.7.1'
  gem 'capybara-webkit', '~> 1.11.1'
  gem 'guard-rspec', '~> 4.7.0'
  gem 'spring', '~> 1.7.1'
  gem 'spring-commands-rspec', '~> 1.0.4'
  gem 'fuubar', '~> 2.0.0'
  gem 'guard-livereload', '~> 2.5.2'
  gem 'capistrano', '3.5.0', require: false
  gem 'capistrano-bundler', '~> 1.1.4', require: false
  gem 'capistrano-rails', '~> 1.1.6', require: false
  gem 'capistrano-rvm', '~> 0.1.2', require: false
  gem 'highline', '~> 1.7.8', require: false
  gem 'awesome_print', '~> 1.6.1'
  gem 'codeclimate-test-reporter', '~> 0.5.0'
  gem 'database_cleaner', '~> 1.5.3'
  gem 'rubocop', '~> 0.40.0', require: false
end

group :development, :test, :heroku do
  # seed script gems
  gem 'ffaker', '~> 2.2.0', require: false
  gem 'ruby-progressbar', '~> 1.8.1', require: false
end

# assets
gem 'sass-rails', '~> 5.0.4'
gem 'coffee-rails', '~> 4.1.1'
gem 'uglifier', '~> 3.0.0'
gem 'bootstrap-sass', '~> 3.3.6'
gem 'font-awesome-rails', '~> 4.6.3.0'

group :development do
  gem 'thin', '~> 1.6.4'
  gem 'rack-mini-profiler', '~> 0.10.1'
  gem 'bullet', '~> 5.1.0'
end

group :production do
  gem 'therubyracer', '~> 0.12.2', require: 'v8'
  gem 'party_foul', '~> 1.5.5'
end

group :heroku do
  gem 'pg', '~> 0.18.4'
  gem 'unicorn', '~> 5.1.0'
  gem 'rack-timeout', '~> 0.4.2'
  gem 'aws-sdk', '< 2.0'
  gem 'rails_12factor', '~> 0.0.3'
end
