desc 'Send email reminder about upcoming checkout'
task email_checkout_reminder: :environment do
  if AppConfig.first.upcoming_checkout_email_active?
    # get all reservations that start today
    upcoming_reservations =
      Reservation.where('checked_out IS NULL and '\
                        '(start_date >= ? and start_date < ?)',
                        Date.current, Date.current + 1)
    Rails.logger.info "Found #{upcoming_reservations.size} reservations that \
      start today. Sending reminder emails..."
    upcoming_reservations.each do |upcoming_reservation|
      Rails.logger.info "Sending reminder for upcoming reservation:\n \
        #{upcoming_reservation.inspect}"
      UserMailer.upcoming_checkout_notification(upcoming_reservation).deliver
    end
  else
    Rails.logger.info 'Upcoming check out emails are not sent by admin. \
      Please change the application settings if you wish to send them.'
  end
end
