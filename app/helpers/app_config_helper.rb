module AppConfigHelper
  def current_favicon_and_options
    if @app_configs.favicon.present?
      '<br><br><strong>Current Favicon: </strong>' + "#{image_tag @app_configs.favicon}"
    end
  end

  def paperclip_field_error(local_form_variable, field)
    # Field must be symbol
    unless local_form_variable.error(field).blank?
      'error'
    end
  end
end