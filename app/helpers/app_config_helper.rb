module AppConfigHelper
  def current_favicon_and_options
    if @app_configs.favicon.present?
      '<br><br><strong>Current Favicon: </strong>' + "#{image_tag @app_configs.favicon}"
    end
  end

end