# frozen_string_literal: true
class StatusController < ActionController::Base
  def index
    render text: 'Application is running.'
  end
end
