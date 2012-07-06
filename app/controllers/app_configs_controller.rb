class AppConfigsController < ApplicationController
  before_filter :require_admin
  # before_filter :bind_pry
  # 
  # def bind_pry
  #   binding.pry
  # end
  
  
  
  def edit
    @app_configs = AppConfig.first || AppConfig.new
  end

  def update
    @app_configs = AppConfig.first   
    if @app_configs.update_attributes(params[:app_config])
      flash[:notice] = "Application settings updated successfully."
      redirect_to :action => 'edit'
    else
      flash[:error] = "Error saving application settings."
      redirect_to catalog_path
    end
  end

end

