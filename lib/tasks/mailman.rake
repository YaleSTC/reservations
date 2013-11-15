desc "Send email reminder about upcoming checkins"
task :send_upcoming_checkin_reminder => :environment do
  if AppConfig.first.upcoming_checkin_email_active?
    #get all reservations that end today and aren't already checked in
    Rails.logger.info("Searching for reservations ending today that aren't yet checked in")
    Rails.logger.info("Search conditions: checked_out IS NOT NULL and checked_in IS NULL and due_date >= #{Time.now.midnight.utc} and due_date < #{Time.now.midnight.utc+1.day}")
    upcoming_reservations = Reservation.find(:all, :conditions => ["checked_out IS NOT NULL and checked_in IS NULL and due_date >= ? and due_date < ?", Time.now.midnight.utc, Time.now.midnight.utc + 1.day])
    puts "Found #{upcoming_reservations.size} reservations due for checkin. Sending reminder emails..."
    upcoming_reservations.each do |upcoming_reservation|
      Rails.logger.info("Sending checkin email reminder for: #{upcoming_reservation.inspect}")
      Rails.logger.info("Maling is currently suspended due to github issue #455, no emails were actually sent.")
      #UserMailer.upcoming_checkin_notification(upcoming_reservation).deliver
    end
    puts "Done!"
  else
    puts "Upcoming check in emails are not sent by admin. Please change the application settings if you wish to send them."
  end
end

desc "Send email reminder about overdue checkins"
task :send_overdue_checkin_reminder => :environment do
  if AppConfig.first.overdue_checkin_email_active?
    #get all reservations that ended before today and aren't already checked in
    Rails.logger.info("Searching for reservations that ended before today and aren't yet checked in")
    Rails.logger.info("Search conditions: checked_out IS NOT NULL and checked_in IS NULL and due_date < #{Time.now.midnight.utc}")
    overdue_reservations = Reservation.find(:all, :conditions => ["checked_out IS NOT NULL and checked_in IS NULL and due_date < ?", Time.now.midnight.utc])
    puts "Found #{overdue_reservations.size} reservations overdue for checkin. Sending reminder emails..."
    overdue_reservations.each do |overdue_reservation|
      Rails.logger.info("Sending overdue checkin reminder for: #{overdue_reservation.inspect}")
      Rails.logger.info("Maling is currently suspended due to github issue #455, no emails were actually sent.")
      #UserMailer.overdue_checkin_notification(overdue_reservation).deliver
    end
    puts "Done!"
  else
    puts "Overdue check in emails are not sent by admin. Please change the application settings if you wish to send them."
  end
end

desc "Send email to admins on reservations with notes"
task :send_reservation_notes => :environment do
  #gets all reservations with notes and sends an email to the admin of the application, to alert them.
  notes_reservations = Reservation.find(:all, :conditions => ["notes IS NOT NULL and checked_out IS NOT NULL and notes_unsent = ?", true])
  puts "Found #{notes_reservations.size} reservations with notes. Sending a reminder email..."
  unless notes_reservations.empty?
    notes_reservations.each do |nr|
      Rails.logger.info("Sending notification to admin about: #{nr.inspect}")
    end
    AdminMailer.notes_reservation_notification(notes_reservations).deliver
  end
  notes_reservations.each do |notes_reservation|
    Rails.logger.info("Updating ")
    notes_reservation.update_attribute(:notes_unsent, false)
  end
  puts "Done!"
end