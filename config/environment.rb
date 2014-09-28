# Load the rails application
require File.expand_path('../application', __FILE__)
require 'rails_extensions'

# Version variable
APP_VERSION = `git describe --tags --abbrev=0`.strip unless defined? APP_VERSION

# CASClient::Frameworks::Rails::Filter.configure(
#   :cas_base_url => "https://secure.its.yale.edu/cas/"
# )
# Initialize the rails application
Reservations::Application.initialize!
