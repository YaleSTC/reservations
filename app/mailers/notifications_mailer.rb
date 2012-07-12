class NotificationsMailer < ActionMailer::Base
  
  def new_message(message)
    @message = message
    mail(:to => AppConfig.first.admin_email, :subject => "#{AppConfig.first.site_title} #{message.subject}", :from => @message.email)
  end
  
end
