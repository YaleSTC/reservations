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

ActionMailer::Base.default_url_options[:host] = "localhost:3000"