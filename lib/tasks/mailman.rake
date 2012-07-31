desc "Send email reminders about upcoming reservations that have not been checked out yet"

 task :mailman => :environment do
   
 if AppConfig.first.upcoming_checkin_email_active?
  #get all reservations that end today and aren't already checked in
  upcoming_reservations = Reservation.find(:all, :conditions => ["checked_out IS NOT NULL and checked_in IS NULL and due_date >= ? and due_date < ?", Time.now.midnight.utc, Time.now.midnight.utc + 1.day])
    puts "Found #{upcoming_reservations.size} reservations due for checkin. Sending reminder emails..."
  upcoming_reservations.each do |upcoming_reservation|
    UserMailer.upcoming_checkin_notification(upcoming_reservation).deliver
  end
  puts "Done!"
  else
  puts "Upcoming check in emails are not sent by admin. Please change the application settings if you wish to send them."
  end

if AppConfig.first.overdue_checkout_email_active?
  #get all reservations that started before today and aren't already checked out
  upcoming_reservations = Reservation.find(:all, :conditions => ["checked_out IS NULL and start_date < ? and  start_date >= ?", Time.now.midnight.utc, Time.now.midnight.utc - 1.day])
  puts "Found #{upcoming_reservations.size} reservations overdue for checkout. Sending reminder emails..."
  upcoming_reservations.each do |upcoming_reservation|
    UserMailer.overdue_checkout_notification(upcoming_reservation).deliver
  end
  puts "Done!"
else
  puts "Overdue checkout emails are not sent by admin. Please change the application settings if you wish to send them."
end 

if AppConfig.first.overdue_checkin_email_active?
  #get all reservations that ended before today and aren't already checked in
  overdue_reservations = Reservation.find(:all, :conditions => ["checked_out IS NOT NULL and checked_in IS NULL and due_date < ?", Time.now.midnight.utc])
  puts "Found #{overdue_reservations.size} reservations overdue for checkin. Sending reminder emails..."
  overdue_reservations.each do |overdue_reservation|
    UserMailer.overdue_checkin_notification(overdue_reservation).deliver
  end
  puts "Done!"
else 
  puts "Overdue check in emails are not sent by admin. Please change the application settings if you wish to send them."
end 

  #gets all reservations with notes and sends an email to the admin of the application, to alert them. 
  notes_reservations = Reservation.find(:all, :conditions => ["notes IS NOT NULL and checked_out IS NOT NULL and notes_unsent = ? or checked_in IS NOT NULL", true])
  puts "Found #{notes_reservations.size} reservations with notes. Sending a reminder email..."
  unless notes_reservations.empty?
    AdminMailer.notes_reservation_notification(notes_reservations).deliver
  end
  notes_reservations.each do |notes_reservation| 
    notes_reservation.notes_unsent = false
    notes_reservation.save
  end
  puts "Done!"

  puts "Mailman done."
end

