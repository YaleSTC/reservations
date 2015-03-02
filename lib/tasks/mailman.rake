desc 'Send email reminder about upcoming checkins'
task send_upcoming_checkin_reminder: :environment do
  if AppConfig.first.upcoming_checkin_email_active?
    # get all reservations that end today and aren't already checked in
    upcoming_reservations =
      Reservation.where('checked_out IS NOT NULL and checked_in IS NULL and '\
                          'due_date >= ? and due_date < ?',
                        Time.zone.today, Time.zone.today + 1.day)
    Rails.logger.info "Found #{upcoming_reservations.size} reservations due "\
                      'for checkin. Sending reminder emails...'
    upcoming_reservations.each do |upcoming_reservation|
      UserMailer.reservation_status_update(upcoming_reservation).deliver
    end
    Rails.logger.info 'Done!'
  else
    Rails.logger.info 'Upcoming check in emails are not sent by admin. '\
                      'Please change the application settings if you wish to '\
                      'send them.'
  end
end

desc 'Send email reminder about overdue checkins'
task send_overdue_checkin_reminder: :environment do
  if AppConfig.first.overdue_checkin_email_active?
    # get all reservations that ended before today and aren't already checked
    # in
    overdue_reservations = Reservation.overdue
    Rails.logger.info "Found #{overdue_reservations.size} reservations "\
                      'overdue for checkin. Sending reminder emails...'
    overdue_reservations.each do |overdue_reservation|
      UserMailer.reservation_status_update(overdue_reservation).deliver
    end
    Rails.logger.info 'Done!'
  else
    Rails.logger.info 'Overdue check in emails are not sent by admin. '\
                      'Please change the application settings if you wish to '\
                      'send them.'
  end
end

desc 'Send email to admins on reservations with notes'
task send_reservation_notes: :environment do
  # gets all reservations with notes and sends an email to the admin of the
  # application, to alert them.
  notes_reservations_out = Reservation.has_notes.checked_out.notes_unsent
  notes_reservations_in = Reservation.has_notes.checked_in.notes_unsent
  Rails.logger.info "Found #{notes_reservations_out.size} reservations "\
                    "checked out with notes and #{notes_reservations_in.size} "\
                    'reservations checked in with notes. Sending a reminder '\
                    'email...'
  unless notes_reservations_out.empty? && notes_reservations_in.empty?
    AdminMailer.notes_reservation_notification(notes_reservations_out,
                                               notes_reservations_in).deliver
  end
  # reset notes_unsent flag on all reservations
  notes_reservations_out.update_all(notes_unsent: false)
  notes_reservations_in.update_all(notes_unsent: false)

  Rails.logger.info 'Done!'
end
