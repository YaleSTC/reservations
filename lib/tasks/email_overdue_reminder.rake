desc 'Send email reminder about overdue checkins'
task email_overdue_reminder: :environment do
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
    Rails.logger.info 'Reservations is not configured to send overdue emails. '\
                      'Please change the application settings if you wish to '\
                      'send them.'
  end
end
