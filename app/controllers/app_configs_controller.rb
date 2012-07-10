class AppConfigsController < ApplicationController
  before_filter :require_admin
  
  def edit
    @app_config = AppConfig.first 
  end

  def update
    @app_config = AppConfig.first   
    if @app_config.update_attributes(params[:app_config])
      flash[:notice] = "Application settings updated successfully."
      redirect_to catalog_path
    else
      render :action => "edit"
      end
  end

end

