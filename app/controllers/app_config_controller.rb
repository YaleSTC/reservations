  class AppConfigController < ApplicationController
  before_filter :require_admin
  
  def index
  end
  
  def edit
  end

  def update
    #update each Setting (field names are the same as Settings attribute names)
    unless params[:site_title].blank?
      params.each do |key, value|
        Settings.send(key+'=', value)
      end
      flash[:notice] = "Application settings updated successfully."
      redirect_to root_path
    else
      flash[:error] = "Site title can't be blank!"
      redirect_to edit_app_config_path
    end
  end
end
