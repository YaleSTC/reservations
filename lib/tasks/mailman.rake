desc "Send email reminders about upcoming reservations that have not been checked out yet"

task :mailman => :environment do
  #get all reservations that end today and aren't already checked in
  upcoming_reservations = Reservation.find(:all, :conditions => ["checked_out IS NOT NULL and checked_in IS NULL and due_date >= ? and due_date < ?", Time.now.midnight.utc, Time.now.midnight.utc + 1.day])
  puts "Found #{upcoming_reservations.size} reservations due for checkin. Sending reminder emails..."
  upcoming_reservations.each do |upcoming_reservation|
    Notifier.deliver_upcoming_checkin_notification(upcoming_reservation)
  end
  puts "Done!"

  #get all reservations that started before today and aren't already checked out
  upcoming_reservations = Reservation.find(:all, :conditions => ["checked_out IS NULL and start_date < ? and  start_date >= ?", Time.now.midnight.utc, Time.now.midnight.utc - 1.day])
  puts "Found #{upcoming_reservations.size} reservations overdue for checkout. Sending reminder emails..."
  upcoming_reservations.each do |upcoming_reservation|
    Notifier.deliver_overdue_checkout_notification(upcoming_reservation)
  end
  puts "Done!"


  #get all reservations that ended before today and aren't already checked in
  overdue_reservations = Reservation.find(:all, :conditions => ["checked_out IS NOT NULL and checked_in IS NULL and due_date < ?", Time.now.midnight.utc])
  puts "Found #{overdue_reservations.size} reservations overdue for checkin. Sending reminder emails..."
  overdue_reservations.each do |overdue_reservation|
    Notifier.deliver_overdue_checkin_notification(overdue_reservation)
  end
  puts "Done!"

  #get all reservations that start today and aren't already checked out
  upcoming_reservations = Reservation.find(:all, :conditions => ["checked_out IS NULL and start_date >= ? and start_date < ?", Time.now.midnight.utc, Time.now.midnight.utc + 1.day])
  affected = []
  overdue = []
  upcoming_reservations.each do |upcoming_reservation|
    affected << upcoming_reservation.equipment_model_id
  end
  overdue_reservations.each do |overdue_reservation|
    overdue << overdue_reservation.equipment_model_id
  end
  puts "Found #{upcoming_reservations.size} reservations due for checkout. Crossreferencing with overdue reservations, sending reminder and warning emails..."
  check = (affected.uniq)&(overdue.uniq)
    check.each do |check|
    inventory_count = EquipmentModel.find(check).equipment_objects
    reserved_count = Reservation.find(:all, :conditions => ["checked_in IS NULL and checked_out IS NULL and equipment_model_id = ? and start_date <= ? and due_date >= ?", check, Time.now.midnight.utc, Time.now.midnight.utc])
    overdue_count = Reservation.find(:all, :conditions => ["checked_in IS NULL and checked_out IS NOT NULL and equipment_model_id = ? and due_date <= ?", check, Time.now.midnight.utc])
    current_count = inventory_count.count - reserved_count.count - overdue_count.count
    if current_count < 0
      reserved_count.each do |reserved_count|
        Notifier.deliver_warning_missing_equipment_notification(reserved_count)
      end
    else
      reserved_count.each do |reserved_count|
        Notifier.deliver_upcoming_checkout_notification(reserved_count)
      end
    end
  end
  puts "Done!"

  puts "Mailman done."
end

