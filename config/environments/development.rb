Reservations::Application.configure do
  # Settings specified here will take precedence over those in config/
  # application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false
  config.reload_classes_only_on_change = false

  config.eager_load = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true

  # Use letter_opener for development mail testing
  if ENV['USER'] == 'vagrant'
    config.action_mailer.delivery_method = :letter_opener_web
  else
    config.action_mailer.delivery_method = :letter_opener
  end
  config.action_mailer.default_url_options = { host: '0.0.0.0:3000' }

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Rails 3 assets
  config.assets.compile = true
  config.assets.compress = false
  config.assets.js_compressor = :uglifier
  config.assets.debug = false
  config.assets.digest = false

  # Set Paperclip path
  Paperclip.options[:command_path] = '/usr/local/bin'

  config.after_initialize do
    Bullet.enable = true
    # Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
    # Bullet.bugsnag = true
    # Bullet.add_footer = true
    # Bullet.stacktrace_includes = [ 'your_gem', 'your_middleware' ]

    # Disable Rack Mini Profiler in certain parts of the application
    Rack::MiniProfiler.config.skip_paths ||= []
    Rack::MiniProfiler.config.skip_paths << '/admin'
  end
end
