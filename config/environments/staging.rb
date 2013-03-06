require File.expand_path('../production', __FILE__)

Reservations::Application.configure do
  #config.serve_static_assets = true
  config.action_mailer.perform_deliveries = false

end
