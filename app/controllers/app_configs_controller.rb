class AppConfigsController < ApplicationController
  before_filter :require_admin
  skip_before_filter :seen_app_configs, only: [:edit]

  def edit
    @app_config = AppConfig.first || AppConfig.new
    @app_config.update_attribute(:viewed, true)
  end

  def update
    @app_config = AppConfig.first

    reset_tos = params[:app_config][:reset_tos_for_users]
    params[:app_config].delete(:reset_tos_for_users)

    if @app_config.update_attributes(params[:app_config])
      if reset_tos == '1'
        User.update_all(['terms_of_service_accepted = ?', false])
      end

      # TODO: Does this work? Checkbox shouldn't have value of 'on'??
      if params[:restore_favicon] == 'on'
        @app_config.favicon = nil
        @app_config.save
      end

      flash[:notice] = "Application settings updated successfully."
      redirect_to catalog_path
    else
      # flash[:error] = "Error saving application settings."
      render :action => 'edit'
    end
  end

end

