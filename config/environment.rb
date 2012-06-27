# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Reservations::Application.initialize!

#initialize AppConfig Observer
#config.active_record.observers = :app_config_observer