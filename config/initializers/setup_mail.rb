ActionMailer::Base.raise_delivery_errors = true

ActionMailer::Base.smtp_settings = {
  :address              => "mail.yale.edu",
  :port                 => 587,
  :domain               => "yale.edu",
  # with these disabled, the server must be connected to the yale network for email to work
  #:authentication      => :login,
  #:user_name           => "username",
  #:password            => "password",
  :enable_starttls_auto => true

}

# mailer host: replace "0.0.0.0:3000" with your root url in production
# this will allow links in e-mail text to function correctly
ActionMailer::Base.default_url_options[:host] = "0.0.0.0:3000"