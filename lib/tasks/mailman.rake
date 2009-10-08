desc "Send email reminders about upcoming reservations that have not been checked out yet"

task (:upcoming => :environment) do
  #get all reservations that start today and aren't already checked out
  upcoming_reservations = Reservation.find(:all, :conditions => ["checked_out IS NULL and start_date >= ? and start < ?", Time.now.midnight.utc, Time.now.midnight.utc + 1.day])
  upcoming_reservations.each do |upcoming_reservation|
    #send reminder email
  end
end