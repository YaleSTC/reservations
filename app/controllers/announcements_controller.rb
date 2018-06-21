# frozen_string_literal: true

class AnnouncementsController < ApplicationController
  load_and_authorize_resource
  before_action :set_current_announcement, only: %i[edit update destroy]

  # ------------- before filter methods ------------- #
  def set_current_announcement
    @announcement = Announcement.find(params[:id])
  end
  # ------------- end before filter methods ------------- #

  def hide
    ids = [params[:id], *cookies.signed[:hidden_announcement_ids]]
    cookies.permanent.signed[:hidden_announcement_ids] = ids
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
      format.js
    end
  end

  def index
    @announcements = Announcement.all
  end

  def new
    @announcement = Announcement.new(starts_at: Time.zone.today,
                                     ends_at: Time.zone.today + 1.day)
  end

  def create
    @announcement = Announcement.new(announcement_params)
    if @announcement.save
      redirect_to(announcements_url,
                  notice: 'Announcement was successfully created.')
    else
      render action: 'new'
    end
  end

  def edit; end

  def update
    if @announcement.update_attributes(announcement_params)
      redirect_to(announcements_url,
                  notice: 'Announcement was successfully updated.')
    else
      render action: 'edit'
    end
  end

  def destroy
    @announcement.destroy
    redirect_to(announcements_url)
  end

  private

  def announcement_params
    params.require(:announcement).permit(:message, :ends_at, :starts_at)
  end
end
