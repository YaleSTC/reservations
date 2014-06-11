class LogController < ApplicationController
  helper LogHelper

  def index
    # Past paper_trail 2.7-stable, Version is namespaced as PaperTrail::Version
    # and so this line will break.
    @versions = Version.order("id desc").all
    # render layout: 'application_with_sidebar'
    @title = "to all Items"
  end

  def version
    @version = Version.find_by_id(params[:id])

    if @version.nil?
      redirect_to action: 'index', notice: "There is no changelog for this item." and return
    end

    @date = @version.created_at
    @user = User.find(@version.whodunnit.to_i)

    @previous = @version.previous
    @previous_user = User.find(@previous.whodunnit.to_i) if @previous

    @next = @version.next
    @next_user = User.find(@next.whodunnit.to_i) if @next
  end

  def history
    @versions = Version.where(item_type: params[:object_type].capitalize, item_id: params[:id])
    # This is safe as long as we only version non-private items.

    unless @versions.exists?
      redirect_to action: 'index', notice: "There is no changelog for this item." and return
    end

    @title = "to " + "#{params[:object_type].tableize.humanize.singularize} #{params[:id]}".split.map( &:capitalize ).join(" ")
    @specific = true
    render "index"
  end
end
