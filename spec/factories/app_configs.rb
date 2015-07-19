# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :app_config do
    upcoming_checkin_email_active true
    upcoming_checkout_email_active true
    reservation_confirmation_email_active true
    site_title 'Reservations Specs'
    admin_email 'my@email.com'
    department_name 'MyString'
    contact_link_location 'MyString'
    home_link_text 'MyString'
    home_link_location 'MyString'
    default_per_cat_page 1
    upcoming_checkin_email_body 'MyText'
    upcoming_checkout_email_body 'MyText'
    overdue_checkin_email_body 'MyText'
    overdue_checkin_email_active true
    terms_of_service 'TOS'
    favicon_file_name 'favicon.ico'
    favicon_content_type 'image/vnd.microsoft.icon'
    favicon_file_size 15
    favicon_updated_at '2013-06-24 14:02:01'
    deleted_missed_reservation_email_body 'MyText'
    send_notifications_for_deleted_missed_reservations true
    notify_admin_on_create false
    checkout_persons_can_edit false
    request_text ''
  end
end
