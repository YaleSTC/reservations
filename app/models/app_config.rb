class AppConfig < ActiveRecord::Base
  has_attached_file :favicon,
                    url: '/system/:attachment/:id/:style/favicon.:extension'

  validates_with AttachmentContentTypeValidator,
                 attributes: :favicon,
                 content_type: 'image/vnd.microsoft.icon',
                 message: 'Must be .ico'

  validates :site_title,   presence: true,
                           length: { maximum: 20 }
  validates :admin_email,
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
    AppConfig.check(prop, val)
  end
end
