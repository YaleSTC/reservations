source "https://rubygems.org"

#standard gems
gem 'rails', '3.2.8'
gem 'mysql2'
gem 'rake'
gem 'rdoc'

#authentication
gem 'rubycas-client-rails'
gem 'rubycas-client', '2.2.1'

#I don't think this is necessary -adam
#gem 'mail'

#scheduling
gem 'whenever'

#ldap integration
gem 'net-ldap'

#attachments
gem 'paperclip'

gem 'permanent_records', '~> 2.1.2'
gem 'nilify_blanks'

#ui
gem 'jquery_datepicker'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jquery-datatables-rails'
gem 'rails3-jquery-autocomplete'
gem 'select2-rails'
gem 'kaminari'

#forms / formatting
gem 'dynamic_form'
gem 'simple_form'
gem 'cocoon'
gem 'redcarpet'



group :development, :test do
  gem "factory_girl_rails"
  gem 'rspec-rails'
  gem 'capybara'
  gem 'guard-livereload'
  gem 'yajl-ruby'
  gem 'ffaker'
  gem 'capistrano'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
  gem 'bootstrap-sass', '~> 2.0.3'
  gem 'font-awesome-rails', :git => "git://github.com/mrnugget/font-awesome-rails.git"
end

group :development do
  gem 'rb-readline'
	gem 'thin'
  gem 'pry'
  gem 'pry-rails'
  gem 'pry-debugger'
  gem 'pry-stack_explorer'
  gem 'pry-remote'
  gem 'letter_opener' 
end

group :production do
  gem 'therubyracer', :require => 'v8'
  gem 'airbrake'
end