class AppConfig < ActiveRecord::Base

  attr_accessible :site_title, :admin_email, :department_name,:contact_link_location,
                  :home_link_text, :home_link_location, :upcoming_checkin_email_body,
                  :upcoming_checkin_email_active, :overdue_checkout_email_body,
                  :overdue_checkout_email_active, :overdue_checkin_email_body,
                  :overdue_checkin_email_active, :reservation_confirmation_email_active,
                  :default_per_cat_page, :terms_of_service, :favicon

  has_attached_file :favicon, url: "/system/:attachment/:id/:style/favicon.:extension"
 
  validates_with AttachmentContentTypeValidator, attributes: :favicon, content_type: 'image/vnd.microsoft.icon',
                                      message: "Must be .ico"


  validates :site_title, 	:presence => true,
							:length => {:maximum => 20 }
  validates :admin_email,
							:format => { :with => /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i }                        
  
end