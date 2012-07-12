class AppConfigsController < ApplicationController
  before_filter :require_admin
  
  def edit
    @app_config = AppConfig.first || AppConfig.new
  end

  def update
    @app_config = AppConfig.first   
    if @app_config.update_attributes(params[:app_config])
      flash[:notice] = "Application settings updated successfully."
      redirect_to catalog_path
    else
      flash[:error] = "Error saving application settings."
      redirect_to :action => 'edit'
    end
  end

end

