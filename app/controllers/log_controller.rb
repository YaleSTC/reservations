class LogController < ApplicationController
  def index
    # Past paper_trail 2.7-stable, Version is namespaced as PaperTrail::Version
    # and so this line will break.
    @all_versions = Version.order("id desc").all
  end
end
