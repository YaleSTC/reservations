# frozen_string_literal: true
class NotificationsMailer < ActionMailer::Base
  def new_message(message)
    @message = message
    mail(to: AppConfig.contact_email,
         subject: "[#{AppConfig.get(:site_title)}] #{message.subject}",
         from: @message.email)
  end
end
