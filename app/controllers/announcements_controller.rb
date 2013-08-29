class AnnouncementsController < ApplicationController
  def hide
    ids = [params[:id], *cookies.signed[:hidden_announcement_ids]]
    cookies.permanent.signed[:hidden_announcement_ids] = ids
    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end

  def index
  	@announcements = Announcement.all
  end

  def new
  	if current_user and current_user.is_admin?(:as => 'admin')
  		@announcement = Announcement.new
  	end
  end

  def create
  	@announcement = Announcement.new(params[:announcement])
  	if @announcement.save
  		respond_to do |format|
  			flash[:notice] = "Successfully created announcement."
  			format.js {render :aciton => 'create_success'}
  		end
  	end
  end

  def update
      if @announcement.update_attributes(params[:announcement])
      	respond_to do |format|
        format.html { redirect_to @announcement, notice: 'Announcement was successfully updated.' }
  		format.js {render :aciton => 'create_success'}
      	end
      end
  end

  def delete
  	@announcement.destroy
  	# respond_to do |format|
  	# 	format.html {}
  end

end
