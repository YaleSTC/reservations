# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  # gives access to all helpers defined within `application_helper`.
  helper :application
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  # to make sure that your mailer uses the devise views
  default sender: ->() { devise_sender }
  default template_path: 'devise/mailer'

  def reset_password_instructions(record, token, opts = {})
    super
  end

  private

  def devise_sender
    admin_email = if AppConfig.check(:admin_email)
                     AppConfig.get :admin_email
                   else
                     'admin@reservations.app'
                   end

    Mail::Address.new admin_email
  end
end
