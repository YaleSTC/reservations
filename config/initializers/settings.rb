#initial app settings, editable through the app_config interface
Settings.admin_email ||= "admin@admin.admin"
Settings.department_name ||= "School of Art Digital Technology Office"

Settings.upcoming_checkout_email_body ||= "Dear @user@,
Please remember to come pick up the following equipment that you reserved:

@equipment_list@

If you do not intend to check these items out, you must cancel your reservation at least 24 hours before it is due for check out. If you frequently miss your reservations then the privilege to make further reservations for the rest of the term will be revoked.

Thank you,
@department_name@"

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