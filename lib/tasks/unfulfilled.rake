desc "Delete missed reservations"
task :delete_missed_reservations => :environment do
  #get all reservations that ended yesterday and weren't checked out
  missed_reservations = Reservation.where("checked_out IS NULL and start_date < ?", Time.now.midnight.utc)
  puts "Found #{missed_reservations.size} reservations that were never missed. Notifying and deleting..."
  
  if AppConfig.first.send_notifications_for_deleted_missed_reservations
    missed_reservations.each do |missed_reservation|  
      UserMailer.missed_reservation_deleted_notification(missed_reservation).deliver
    end
  end
  
  if AppConfig.first.delete_missed_reservations
    missed_reservations.each do |missed_reservation|  
      missed_reservation.destroy
    end
  end

  puts "Done!"
end

