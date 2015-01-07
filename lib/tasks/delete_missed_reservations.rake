desc 'Delete missed reservations'
task delete_missed_reservations: :environment do
  # remove all missed reservations older than the current day
  # do not delete if appconfig isn't set up or if
  # res exp date is not set
  unless AppConfig.first.blank? || AppConfig.first.res_exp_time.blank?
    time = AppConfig.first.res_exp_time
    missed_reservations = Reservation.where(
      'checked_out IS NULL and due_date < ?', Date.current - time.days)
    Rails.logger.info "Found #{missed_reservations.size} reservations"

    if AppConfig.first.send_notifications_for_deleted_missed_reservations
      missed_reservations.each do |missed_reservation|
        Rails.logger.info "Sending notification for:\n "\
          "#{missed_reservation.inspect}"
        UserMailer.missed_reservation_deleted_notification(missed_reservation)
          .deliver
      end
    end

    missed_reservations.each do |missed_reservation|
      Rails.logger.info "Deleting reservation:\n #{missed_reservation.inspect}"
      missed_reservation.destroy
    end

    Rails.logger.info 'Finished processing missed reservations.'
  end
end
