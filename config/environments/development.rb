Rails.application.configure do
  # Settings specified here will take precedence over those in config/
  # application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Use letter_opener for development mail testing
  if ENV['USER'] == 'vagrant'
    config.action_mailer.delivery_method = :letter_opener_web
  else
    config.action_mailer.delivery_method = :letter_opener
  end
  config.action_mailer.default_url_options = { host: '0.0.0.0:3000' }

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all
  # assets, yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

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
