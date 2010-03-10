desc "Send email reminders about upcoming reservations that have not been checked out yet"

task (:mailman => :environment) do
  #get all reservations that start today and aren't already checked out
  upcoming_reservations = Reservation.find(:all, :conditions => ["checked_out IS NULL and start_date >= ? and start_date < ?", Time.now.midnight.utc, Time.now.midnight.utc + 1.day])
  puts "Found #{upcoming_reservations.size} reservations due for checkout. Sending reminder emails..."
  upcoming_reservations.each do |upcoming_reservation|
    Notifier.deliver_upcoming_checkout_notification(upcoming_reservation)
  end
  puts "Done!"
  
  #get all reservations that end today and aren't already checked in
  upcoming_reservations = Reservation.find(:all, :conditions => ["checked_out IS NOT NULL and checked_in IS NULL and due_date >= ? and due_date < ?", Time.now.midnight.utc, Time.now.midnight.utc + 1.day])
  puts "Found #{upcoming_reservations.size} reservations due for checkin. Sending reminder emails..."
  upcoming_reservations.each do |upcoming_reservation|
    Notifier.deliver_upcoming_checkin_notification(upcoming_reservation)
  end
  puts "Done!"
  
  #get all reservations that started before today and aren't already checked out
  upcoming_reservations = Reservation.find(:all, :conditions => ["checked_out IS NULL and start_date <= ? and  start_date > ?", Time.now.midnight.utc, Time.now.midnight.utc - 1.day])
  puts "Found #{upcoming_reservations.size} reservations overdue for checkout. Sending reminder emails..."
  upcoming_reservations.each do |upcoming_reservation|
    Notifier.deliver_overdue_checkout_notification(upcoming_reservation)
  end
  puts "Done!"
  
  #get all reservations that ended before today and aren't already checked in
  upcoming_reservations = Reservation.find(:all, :conditions => ["checked_out IS NOT NULL and checked_in IS NULL and due_date < ?", Time.now.midnight.utc])
  puts "Found #{upcoming_reservations.size} reservations overdue for checkin. Sending reminder emails..."
  upcoming_reservations.each do |upcoming_reservation|
    Notifier.deliver_overdue_checkin_notification(upcoming_reservation)
  end
  puts "Done!"
  
  puts "Mailman done."
end