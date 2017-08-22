# frozen_string_literal: true

class StatusController < ActionController::Base
  protect_from_forgery with: :exception
  def index
    render plain: 'Application is running.'
  end
end
