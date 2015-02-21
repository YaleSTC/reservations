# Load the rails application
require File.expand_path('../application', __FILE__)
require 'rails_extensions'

# Version variable
if Dir.exist?('.git/') && !defined? APP_VERSION
  APP_VERSION = `git describe --tags --abbrev=0`.strip
end

unless defined? APP_VERSION
  File.open('CHANGELOG.md', 'r') do |f|
    while line = f.gets # rubocop:disable AssignmentInCondition
      version = line[/v[0-9]+\.[0-9]+\.[0-9]+/]
      if version
        APP_VERSION = version
        break
      end
    end
  end
end

# Initialize the rails application
Reservations::Application.initialize!
