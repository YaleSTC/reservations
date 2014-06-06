class LogController < ApplicationController
  def index
    @all_versions = Version.order("id desc").all
  end
end
