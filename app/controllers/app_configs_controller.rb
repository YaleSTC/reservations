class AppConfigsController < ApplicationController
  before_filter :require_admin
  
  def edit
    if @app_config.nil?
      @app_config = AppConfig.first
    else
      @app_config = AppConfig.find(params[:id])     
    end 
  end

  def update
     #update each Setting (field names are the same as Settings attribute names)
     @app_config = AppConfig.new
      params.each do |key, value|
        Settings.send(key+'=', value)
      end     
     if @app_config.update_attributes(params[:app_config])
     flash[:notice] = "Application settings updated successfully."
     redirect_to :action => 'edit'
   else
     flash[:error] = "Error"
   end
   end
end

