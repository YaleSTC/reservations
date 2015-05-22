desc 'Send emails about missed reservations'
task email_missed_reservations: :environment do
  # get all reservations that are approved and missed, send an email to
  # user to inform them
  if AppConfig.first.send_notifications_for_deleted_missed_reservations
    missed_reservations = Reservation.missed.not_flagged(:missed_email_sent)

    Rails.logger.info "Found #{missed_reservations.size} missed reservations\
      , sending emails."

    missed_reservations.each do |missed_reservation|
      Rails.logger.info "Sending email for reservation:\n \
        #{missed_reservation.inspect}"
      UserMailer.reservation_status_update(missed_reservation).deliver
      missed_reservation.flag(:missed_email_sent)
      missed_reservation.save!
    end
  end
end
