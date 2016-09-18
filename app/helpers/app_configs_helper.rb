# frozen_string_literal: true
module AppConfigsHelper
  def current_favicon_and_options
    return unless @app_configs.favicon.present?
    '<br><br><strong>Current Favicon: </strong> '\
        "#{image_tag @app_configs.favicon}"
  end
end
