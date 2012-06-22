#initial app settings, editable through the app_config interface
begin
  Settings.site_title ||= "Reservations"
  Settings.admin_email ||= "admin@admin.admin"
  Settings.department_name ||= "School of Art Digital Technology Office"
  Settings.contact_link_text ||= "Contact Us"
  Settings.contact_link_location ||= "mailto:contact.us@change.com"
  Settings.home_link_text  ||= "Home"
  Settings.home_link_location ||= "http://clc.yale.edu"
  Settings.default_per_cat_page ||= 20
  Settings.upcoming_checkin_email_body ||= "Dear @user@,
  Please remember to return the equipment you borrowed from us:

  @equipment_list@

  If the equipment is returned after 4 pm on @return_date@ you will be charged a late fee or replacement fee. Repeated late returns will result in the privilege to make further reservations for the rest of the term to be revoked.

  Thank you,
  @department_name@"
  Settings.overdue_checkout_email_body ||= "Dear @user@,
  You have missed a scheduled equipment checkout, so your equipment may be released and checked out to other students.

  Thank you,
  @department_name@"
  Settings.overdue_checkin_email_body ||= "Dear @user@,
  You were supposed to return the equipment you borrowed from us on @return_date@ but because you have failed to do so, you will be charged @late_fee@ / day until the equipment is returned. Failure to return equipment will result in replacement fees and revocation of borrowing privileges.

  Thank you,
  @department_name@"
  
rescue
  puts "Settings table does not exist yet; please run rake db:migrate."
end
