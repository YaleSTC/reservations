# Use this hook to configure devise mailer, warden hooks and so forth.
# Many of these configuration options can be set straight in your model.
Devise.setup do |config|
  # The secret key used by Devise. Devise uses this key to generate
  # random tokens. Changing this key will render invalid all existing
  # confirmation, reset password and unlock tokens in the database.
  config.secret_key = Rails.application.secrets.devise_secret_key

  # ==> Mailer Configuration
  # Configure the e-mail address which will be shown in Devise::Mailer,
  # note that it will be overwritten if you use your own mailer class
  # with default "from" parameter.
  config.mailer_sender = AppConfig.table_exists? && !AppConfig.first.nil? ? AppConfig.first.admin_email : 'admin@example.com'

  # ==> ORM configuration
  # Load and configure the ORM. Supports :active_record (default) and
  # :mongoid (bson_ext recommended) by default. Other ORMs may be
  # available as additional gems.
  require 'devise/orm/active_record'

  # By default Devise will store the user in session. You can skip storage for
  # particular strategies by setting this option.
  # Notice that if you are skipping storage for all authentication paths, you
  # may want to disable generating routes to Devise's sessions controller by
  # passing skip: :sessions to `devise_for` in your config/routes.rb
  config.skip_session_storage = [:http_auth]

  # ==> Configuration for :database_authenticatable
  # For bcrypt, this is the cost for hashing the password and defaults to 10. If
  # using other encryptors, it sets how many times you want the password re-encrypted.
  #
  # Limiting the stretches to just one in testing will increase the performance of
  # your test suite dramatically. However, it is STRONGLY RECOMMENDED to not use
  # a value less than 10 in other environments. Note that, for bcrypt (the default
  # encryptor), the cost increases exponentially with the number of stretches (e.g.
  # a value of 20 is already extremely slow: approx. 60 seconds for 1 calculation).
  config.stretches = Rails.env.test? ? 1 : 10

  # Setup a pepper to generate the encrypted password.
  config.pepper = Rails.application.secrets.devise_pepper

  # ==> Configuration for :recoverable

  # Time interval you can reset your password with a reset password key.
  # Don't put a too small interval or your users won't have the time to
  # change their passwords.
  config.reset_password_within = 6.hours

  # ==> devise_cas_authenticatable configuration
  if ENV['CAS_AUTH']

    # configure the base URL of your CAS server
    config.cas_base_url = Rails.application.secrets.cas_base_url

    # you can override these if you need to, but cas_base_url is usually
    # enough
    # config.cas_login_url = "https://cas.myorganization.com/login"
    # config.cas_logout_url = "https://cas.myorganization.com/logout"
    # config.cas_validate_url = "https://cas.myorganization.com/serviceValidate"

    # By default, devise_cas_authenticatable will create users.  If you would
    # rather require user records to already exist locally before they can
    # authenticate via CAS, uncomment the following line.
    config.cas_create_user = false

    # You can enable Single Sign Out, which by default is disabled.
    config.cas_enable_single_sign_out = true

  end

end
