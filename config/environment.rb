# Load the rails application
require File.expand_path('../application', __FILE__)
require 'rails_extensions'

# Version variable
APP_VERSION = `git describe --tags --abbrev=0`.strip unless defined? APP_VERSION

unless defined? APP_VERSION
  File.open('CHANGELOG.md', 'r') do |f|
    while line = f.gets
      version = line.sub('### v', 'v')
      if version != line
        APP_VERSION = version.strip
        break
      end
    end
  end
end

CASClient::Frameworks::Rails::Filter.configure(
  :cas_base_url => "https://secure.its.yale.edu/cas/"
)
# Initialize the rails application
Reservations::Application.initialize!
