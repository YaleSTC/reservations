source 'https://rubygems.org'

ruby '2.1.2' # Version in .ruby-version must match

# standard gems
gem 'rails', '~> 4.1.9'
gem 'mysql2', '~> 0.3.18'
gem 'rake', '~> 10.4.2'
gem 'rdoc', '~> 4.2.0'

# simulate environment variables
group :development, :test do
  gem 'dotenv-rails', '~> 1.0.2'
end

# authentication / authorization
gem 'devise', '~> 3.4.1'
gem 'devise_cas_authenticatable', '~> 1.3.7' # if ENV['CAS_AUTH']
gem 'cancancan', '~> 1.10.1'

# scheduling
gem 'whenever', '~> 0.9.4'

# administrative panel
gem 'rails_admin', '~> 0.6.6'

# seed script gems
gem 'ffaker', '~> 1.32.1'
gem 'ruby-progressbar', '~> 1.7.1'

# ldap integration
gem 'net-ldap', '~> 0.11'

# attachments
gem 'paperclip', '~> 4.2.1'

gem 'permanent_records', '~> 3.2.0'
gem 'nilify_blanks', '~> 1.2.0'

# ui
gem 'jquery-rails', '~> 3.1.2'
gem 'jquery-ui-rails', '~> 5.0.3'
gem 'jquery-datatables-rails', '~> 3.1.1'
gem 'rails4-autocomplete', '~> 1.1.1'
gem 'select2-rails', '~> 3.5.9.3'
gem 'kaminari', '~> 0.16.3'
gem 'draper', '~> 1.4.0'

# forms / formatting
gem 'simple_form', '~> 3.1.0'
gem 'cocoon', '~> 1.2.6'
gem 'redcarpet', '~> 3.2.2'

group :development, :test do
  gem 'factory_girl_rails', '~> 4.5.0'
  gem 'rspec-rails', '~> 3.2.0'
  gem 'shoulda-matchers', '~> 2.8.0'
  gem 'capybara', '~> 2.4.4'
  gem 'guard-rspec', '~> 4.5.0'
  gem 'spring', '~> 1.3.2'
  gem 'spring-commands-rspec', '~> 1.0.4'
  gem 'fuubar', '~> 2.0.0'
  gem 'guard-livereload', '~> 2.4.0'
  gem 'yajl-ruby', '~> 1.2.1'
  gem 'capistrano',  '~> 3.3.5'
  gem 'capistrano-bundler', '~> 1.1.2'
  gem 'capistrano-rails', '~> 1.1.2'
  gem 'capistrano-rvm', '~> 0.1.2'
  gem 'awesome_print', '~> 1.6.1'
  gem 'codeclimate-test-reporter'
  gem 'database_cleaner'
  gem 'rubocop', require: false
end

# Gems used only for assets and not required
# in production environments by default.
gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'

gem 'bootstrap-sass', '~> 3.3.1'
gem 'font-awesome-rails'

group :development do
  gem 'thin'
  gem 'pry'
  gem 'pry-rails'
  gem 'pry-byebug'
  gem 'pry-stack_explorer'
  gem 'pry-remote'
  gem 'letter_opener'
  gem 'letter_opener_web'
  gem 'rack-mini-profiler'
  gem 'bullet'
  gem 'travis'
end

group :production do
  gem 'therubyracer', require: 'v8'
  gem 'party_foul'
  gem 'dotenv-deployment'
  # for Heroku
  gem 'pg'
  gem 'unicorn'
  gem 'rack-timeout'
  gem 'rails_12factor'
end
