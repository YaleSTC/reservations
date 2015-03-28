class NotificationsMailer < ActionMailer::Base
  def new_message(message)
    @message = message
    mail(to: AppConfig.get(:contact_link_location),
         subject: "[#{AppConfig.get(:site_title)}] #{message.subject}",
         from: @message.email)
  end
end
