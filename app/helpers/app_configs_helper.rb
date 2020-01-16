# frozen_string_literal: true

module AppConfigsHelper
  def current_favicon_and_options
    return if @app_configs.favicon.blank?
    '<br><br><strong>Current Favicon: </strong> '\
        "#{image_tag @app_configs.favicon.url unless @app_configs.favicon.nil?}"
  end
end
