desc "Delete missed reservations"
task :delete_missed_reservations => :environment do
  #get all reservations that ended yesterday and weren't checked out
  missed_reservations = Reservation.where("checked_out IS NULL and start_date < ?", Time.now.midnight.utc)
  Rails.logger.info "Found #{missed_reservations.size} reservations"
  
  if AppConfig.first.send_notifications_for_deleted_missed_reservations
    missed_reservations.each do |missed_reservation|  
      Rails.logger.info "Sending notification for:\n #{missed_reservation.inspect}"
      UserMailer.missed_reservation_deleted_notification(missed_reservation).deliver
    end
  end
  
  if AppConfig.first.delete_missed_reservations

    missed_reservations.each do |missed_reservation|  
      Rails.logger.info "Deleting reservation:\n #{missed_reservation.inspect}"
      missed_reservation.destroy
    end
  end

  Rails.logger.info "Finished processing missed reservations."
end

