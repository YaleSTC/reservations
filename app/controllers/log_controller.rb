class LogController < ApplicationController
  helper LogHelper

  def index
    # Past paper_trail 2.7-stable, Version is namespaced as PaperTrail::Version
    # and so this line will break.
    @versions = Version.order("id desc").all
    # render layout: 'application_with_sidebar'
    @title = "to all Reservations"
  end

  def version
    @version = Version.find(params[:id])
    @date = @version.created_at
    @user = User.find(@version.whodunnit.to_i)

    @previous = @version.previous
    @previous_user = User.find(@previous.whodunnit.to_i) if @previous

    @next = @version.next
    @next_user = User.find(@next.whodunnit.to_i) if @next
  end

  def history
    @versions = Version.where(item_type: "Reservation", item_id: params[:id])
    @title = "to Reservation #{params[:id]}"
    @specific = true
    render "index"
  end
end
