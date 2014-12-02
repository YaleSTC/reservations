source 'https://rubygems.org'

ruby '2.1.2' # Version in .ruby-version must match

#standard gems
gem 'rails', '~> 4.1.5'
gem 'mysql2'
gem 'rake', '~> 10.3.2'
gem 'rdoc', '~> 4.1.2'

# simulate environment variables
group :development, :test do
  gem 'dotenv-rails', '~> 1.0.2'
end

# authentication / authorization
gem 'devise', '~> 3.3.0'
gem 'devise_cas_authenticatable', '~> 1.3.7'# if ENV['CAS_AUTH']
gem 'cancancan'

#scheduling
gem 'whenever'

gem 'rails_admin'

#ldap integration
gem 'net-ldap'

#attachments
gem 'paperclip'

# see issue #1040 for details, look for an update past 3.1.6
gem 'permanent_records', git: 'https://github.com/JackDanger/permanent_records.git', ref: 'ea027de9'
gem 'nilify_blanks'

#ui
gem 'jquery-rails', '~> 3.1.2'
gem 'jquery-ui-rails', '~> 5.0.1'
gem 'jquery-datatables-rails'
gem 'rails4-autocomplete'
gem 'select2-rails'
gem 'kaminari'
gem 'draper', '~> 1.3'

#forms / formatting
gem 'dynamic_form'
gem 'simple_form'
gem 'cocoon'
gem 'redcarpet'

group :development, :test do
  gem 'factory_girl_rails'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'capybara'
  gem 'guard-rspec'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'fuubar', '~> 2.0.0rc1'
  gem 'guard-livereload'
  gem 'yajl-ruby'
  gem 'ffaker'
  gem 'capistrano',  '~> 3.1'
  gem 'capistrano-bundler', '~> 1.1.2'
  gem 'capistrano-rails', '~> 1.1'
  gem 'capistrano-rvm'
  gem 'awesome_print'
  gem 'ruby-progressbar'
  gem 'codeclimate-test-reporter'
  gem 'database_cleaner'
end

# Gems used only for assets and not required
# in production environments by default.
gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'
gem 'bootstrap-sass', '~> 2.0.3'
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

group :production, :staging do
  gem 'therubyracer', require: 'v8'
  gem 'party_foul'
  gem 'dotenv-deployment'
end
