desc 'Send email reminder about upcoming check-ins'
task email_checkin_reminder: :environment do
  if AppConfig.first.upcoming_checkin_email_active?
    # get all reservations that end today and aren't already checked in
    upcoming_reservations = Reservation.due_soon
    Rails.logger.info "Found #{upcoming_reservations.size} reservations due "\
                      'for check-in. Sending reminder emails...'
    upcoming_reservations.each do |upcoming_reservation|
      UserMailer.reservation_status_update(upcoming_reservation).deliver
    end
    Rails.logger.info 'Done!'
  else
    Rails.logger.info 'Reservations is not configured to send upcoming '\
                      'check-in emails. Please change the application '\
                      'settings if you wish to send them.'
  end
end
