# frozen_string_literal: true
class ContactController < ApplicationController
  skip_before_action :authenticate_user!, unless: :guests_disabled?

  def new
    @message = Message.new
  end

  def create
    @message = Message.new(params[:message])
    if @message.valid?
      NotificationsMailer.new_message(@message).deliver_now
      redirect_to(root_path, notice: 'Message was successfully sent.')
    else
      flash[:error] = 'Please fill all fields.'
      render :new
    end
  end
end
