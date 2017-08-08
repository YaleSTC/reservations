# frozen_string_literal: true

require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups(:default, Rails.env))

module Reservations
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified
    # here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %w[/lib/extras /lib/seed /lib/job_helpers
                                /lib/].map { |s| "#{config.root}#{s}" }
    config.watchable_dirs['lib'] = [:rb]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector,
    #                                  :forum_observer

    # Set Time.zone default to the specified zone and make Active Record
    # auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names.
    # Default is UTC.
    config.time_zone = 'Eastern Time (US & Canada)'

    # Do not swallow errors in after_commit/after_rollback callbacks.
    # REMOVED IN RAILS 5 -- this means we need to explicitly throw in callbacks
    # config.active_record.raise_in_transactional_callbacks = true

    # The default locale is :en and all translations from
    # config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path +=
    #   Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always
    # included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = 'utf-8'

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # config.rubycas.cas_base_url = 'https://secure.its.yale.edu/cas/'

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Change the path that assets are served from
    # config.assets.prefix = "/assets"

    # Add app/assets/fonts to the asset pipeline known paths
    config.assets.paths << Rails.root.join('app', 'assets', 'fonts')

    # Ensures that each controller doesn't load every helper in the application
    config.action_controller.include_all_helpers = false

    PermanentRecords.dependent_record_window = 10.seconds

    # set up routing options for Reports (at a minimum)
    config.after_initialize do
      Rails.application.routes.default_url_options =
        config.action_mailer.default_url_options
    end
  end
end
