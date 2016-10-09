# frozen_string_literal: true
module AppConfigGenerator
  DEFAULT_MSGS = File.join(Rails.root, 'db', 'default_messages')
  TOS_TEXT = File.read(File.join(DEFAULT_MSGS, 'tos_text'))
  UPCOMING_CHECKIN_RES_EMAIL = File.read(File.join(DEFAULT_MSGS,
                                                   'upcoming_checkin_email'))
  UPCOMING_CHECKOUT_RES_EMAIL = File.read(File.join(DEFAULT_MSGS,
                                                    'upcoming_checkout_email'))
  OVERDUE_RES_EMAIL_BODY = File.read(File.join(DEFAULT_MSGS, 'overdue_email'))
  DELETED_MISSED_RES_EMAIL = File.read(File.join(DEFAULT_MSGS,
                                                 'deleted_missed_email'))
  def self.generate
    return AppConfig.first if AppConfig.first
    AppConfig.create! do |ac|
      ac.terms_of_service = TOS_TEXT
      ac.reservation_confirmation_email_active = false
      ac.overdue_checkin_email_active = false
      ac.site_title = 'Reservations'
      ac.upcoming_checkin_email_active = false
      ac.notify_admin_on_create = false
      ac.admin_email = 'admin@admin.com'
      ac.department_name = 'Department'
      ac.contact_link_location = 'contact@admin.com'
      ac.home_link_text = 'home_link'
      ac.home_link_location = 'Canada'
      ac.deleted_missed_reservation_email_body = DELETED_MISSED_RES_EMAIL
      ac.default_per_cat_page = 10
      ac.request_text = ''
      ac.upcoming_checkin_email_body = UPCOMING_CHECKIN_RES_EMAIL
      ac.upcoming_checkout_email_body = UPCOMING_CHECKOUT_RES_EMAIL
      ac.overdue_checkin_email_body = OVERDUE_RES_EMAIL_BODY
    end
  end
end
