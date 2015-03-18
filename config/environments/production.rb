Reservations::Application.configure do
  # Settings specified here will take precedence over those in config/
  # application.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true
  config.eager_load = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = 'X-Sendfile'

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_assets = ENV['SERVE_STATIC'].present?

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # mailer host: replace 'example.com' with your root url
  # this will allow links in email text to function correctly
  config.action_mailer.default_url_options =
    { host: "#{ENV['RAILS_HOST_NAME']}#{ENV['RAILS_RELATIVE_URL_ROOT']}" }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Choose the compressors to use
  config.assets.js_compressor  = :uglifier
  # config.assets.css_compressor = :yui

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs.
  config.assets.digest = true

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = Rails.root.join('public/assets')

  # Precompile additional assets (application.js, application.css, and all
  # non-JS/CSS are already added)
  config.assets.precompile += %w(print.css)

  # set up PartyFoul
  config.middleware.use('PartyFoul::Middleware') if ENV['PARTY_FOUL_TOKEN']
end
