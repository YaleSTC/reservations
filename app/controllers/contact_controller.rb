class ContactController < ApplicationController
  
  def new
    @message = Message.new
  end

  def create
    @message = Message.new(params[:message])
    if @message.valid?
      NotificationsMailer.new_message(@message).deliver
      redirect_to(root_path, :notice => "Message was successfully sent.")
    else
      flash[:error] = "Please fill all fields."
      render :new
    end
  end

end
