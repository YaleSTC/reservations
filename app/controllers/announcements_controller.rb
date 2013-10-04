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

  # def show
  # end

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
        format.html {redirect_to announcements_url}
  		end
  	end
  end

  def edit
    @announcement = Announcement.find(params[:id])
  end

  def update
    @announcement = Announcement.find(params[:id])
      if  @announcement.update_attributes(params[:announcement])
      	respond_to do |format|   
          format.html { redirect_to announcements_url, notice: 'Announcement was successfully updated.' }
  		     format.js {render :aciton => 'create_success'}
      end        
      else
        render :action => 'edit'
      end
      

  end

  def destroy 
  	@announcement = Announcement.find(params[:id])
    if @announcement.present?
      @announcement.destroy
      redirect_to announcements_url
    else
      redirect_to :back
end
end

  #   @announcement.delete
  # 	 respond_to do |format|
  # 	 	format.html {redirect_to announcements_url}
  #    end
  # end


end
