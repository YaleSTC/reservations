# frozen_string_literal: true

class AppConfig < ApplicationRecord
  has_attached_file :favicon,
                    url: paperclip_url(filename: 'favicon'),
                    path: ':rails_root/public/attachments/app_configs/'\
                      ':attachment/:id/:style/favicon.:extension'

  validates_with AttachmentContentTypeValidator,
                 attributes: :favicon,
                 content_type: 'image/vnd.microsoft.icon',
                 message: 'Must be .ico'

  validates :site_title,   presence: true,
                           length: { maximum: 20 }
  validates :admin_email,
            presence: true,
            format: { with: /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i }
  validates :contact_link_location,
            allow_blank: true,
            format: { with: /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i }
  validates :default_per_cat_page, numericality: { only_integer: true }

  def self.check(prop, val = false)
    # Check the property given in prop
    # return val (default false) if AppConfig.first is nil
    ap = AppConfig.first
    return val unless ap
    ap.send(prop)
  end

  def self.get(prop, val = false)
    # alias for semantics
    check(prop, val)
  end

  # Returns the to e-mail for contact form submissions, defaulting to the admin
  # e-mail address if no separate address is specified
  def self.contact_email
    contact_email = get(:contact_link_location, nil)
    if contact_email.blank?
      get(:admin_email, nil)
    else
      contact_email
    end
  end
end
