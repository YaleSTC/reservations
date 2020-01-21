# frozen_string_literal: true

module AppConfigsHelper
  def current_favicon_and_options
    return unless @app_configs.favicon.attached?
    '<br><br><strong>Current Favicon: </strong> '\
        "#{current_favicon}"
  end

  private

  def current_favicon
    resized_favicon = @app_configs
                      .favicon
                      .variant(resize('150x150'))

    image_tag resized_favicon
  end
end
