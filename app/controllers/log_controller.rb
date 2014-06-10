class LogController < ApplicationController
  def index
    # Past paper_trail 2.7-stable, Version is namespaced as PaperTrail::Version
    # and so this line will break.
    @all_versions = Version.order("id desc").all
    # render layout: 'application_with_sidebar'
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
end
