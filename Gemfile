source 'https://rubygems.org'

ruby '2.1.1'

#standard gems
gem 'rails', '3.2.14'
gem 'mysql2', '0.3.16'
gem 'rake'
gem 'rdoc'

#authentication
gem 'rubycas-client-rails'
gem 'rubycas-client', '2.2.1'
gem 'cancan'

#scheduling
gem 'whenever'

gem 'activeadmin'

#ldap integration
gem 'net-ldap'

#attachments
gem 'paperclip'

gem 'permanent_records'
gem 'nilify_blanks'

#ui
gem 'jquery_datepicker'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jquery-datatables-rails'
gem 'rails3-jquery-autocomplete'
gem 'select2-rails'
gem 'kaminari', '~> 0.16.1'
gem 'spinjs-rails'

#forms / formatting
gem 'dynamic_form'
gem 'simple_form'
gem 'cocoon'
gem 'redcarpet'


# auditting / logging
gem 'paper_trail', git: "https://github.com/airblade/paper_trail.git", branch: "2.7-stable"

group :development, :test do
  gem 'factory_girl_rails'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'capybara', '~> 2.0.0'
  gem 'guard-rspec'
  gem 'spork-rails'
  gem 'guard-spork'
  gem 'fuubar'
  gem 'guard-livereload'
  gem 'yajl-ruby'
  gem 'ffaker'
  gem 'capistrano'
  gem 'awesome_print'
  gem 'ruby-progressbar'
  gem 'codeclimate-test-reporter'
  gem 'parallel_tests'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
  gem 'bootstrap-sass', '~> 2.0.3'
  gem 'font-awesome-rails', '~> 4.1.0'
end

group :development do
  gem 'thin'
  gem 'pry'
  gem 'pry-rails'
  gem 'pry-byebug'
  gem 'pry-stack_explorer'
  gem 'pry-remote'
  gem 'letter_opener'
  gem 'letter_opener_web', '~> 1.1.0'
  gem 'rack-mini-profiler'
  gem 'bullet'
end

group :production, :staging do
  gem 'therubyracer', require: 'v8'
  gem 'airbrake'
end
