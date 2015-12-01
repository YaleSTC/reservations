ActionMailer::Base.raise_delivery_errors = true

ActionMailer::Base.smtp_settings = {
  address: Rails.application.secrets.smtp_address,
  port: Rails.application.secrets.smtp_port,
  domain: Rails.application.secrets.smtp_domain,
  enable_starttls_auto: true
}

# optional server authentication
if ENV['RES_SMTP_AUTH']
  ActionMailer::Base.smtp_settings[:authentication] = :login
  ActionMailer::Base.smtp_settings[:user_name] =
    Rails.application.secrets.smtp_username
  ActionMailer::Base.smtp_settings[:password] =
    Rails.application.secrets.smtp_password
end

# logging of automatically sent emails
class MailObserver
  def self.delivered_email(message)
    if ENV['LOG_EMAILS']
      Rails.logger.info "Sent #{message.subject} to #{message.to}"
    end
  end
end
ActionMailer::Base.register_observer(MailObserver)
