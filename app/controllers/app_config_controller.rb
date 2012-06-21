class AppConfigController < ApplicationController
  before_filter :require_admin
  
  def edit
  end

  def update
     #update each Setting (field names are the same as Settings attribute names)
     params.each do |key, value|
       Settings.send(key+'=', value)
     end
     flash[:notice] = "Application settings updated successfully."
     redirect_to :action => 'edit'
   end
end

