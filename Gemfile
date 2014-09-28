source 'https://rubygems.org'

ruby '2.1.2' # Version in .ruby-version must match

#standard gems
gem 'rails', '4.1.4'
gem 'mysql2'
gem 'rake'
gem 'rdoc'

# rails 4 transition gems
gem 'activerecord-session_store'

#authentication
#gem 'rubycas-client-rails'

gem 'rubycas-client', :git => 'git://github.com/rubycas/rubycas-client.git'
gem 'cancancan'

#scheduling
gem 'whenever'

gem 'rails_admin'

#ldap integration
gem 'net-ldap'

#attachments
gem 'paperclip'

gem 'permanent_records'
gem 'nilify_blanks'

#ui
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jquery-datatables-rails'
gem 'rails4-autocomplete'
gem 'select2-rails'
gem 'kaminari'
gem 'spinjs-rails'

#forms / formatting
gem 'dynamic_form'
gem 'simple_form'
gem 'cocoon'
gem 'redcarpet'


# auditting / logging
gem 'paper_trail', '~> 3.0.5'

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
  gem 'capistrano'
  gem 'awesome_print'
  gem 'ruby-progressbar'
  gem 'codeclimate-test-reporter'
  gem 'parallel_tests'
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
  gem 'guard-spork'
end

group :production, :staging do
  gem 'therubyracer', require: 'v8'
  gem 'party_foul'
end
