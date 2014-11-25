ActionMailer::Base.raise_delivery_errors = true

ActionMailer::Base.smtp_settings = {
  :address              => Rails.application.secrets.smtp_address,
  :port                 => Rails.application.secrets.smtp_port,
  :domain               => Rails.application.secrets.smtp_domain,
  # with these disabled, the server must be connected to the yale network for email to work
  if ENV['RES_SMTP_AUTHENTICATION']
    :authentication      => :login,
    :user_name           => Rails.application.secrets.smtp_username,
    :password            => Rails.application.secrets.smtp_password,
  end
  :enable_starttls_auto => true

}