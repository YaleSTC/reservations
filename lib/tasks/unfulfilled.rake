desc "Delete unfulfilled reservations"
task :unfulfilled => :environment do
  #get all reservations that ended yesterday and weren't checked out
  past_reservations = Reservation.find(:all, :conditions => ["checked_out IS NULL and due_date < ?", Time.now.midnight.utc])
  puts "Found #{past_reservations.size} reservations that were never fulfilled. Deleting..."
  past_reservations.each do |past_reservation|
    past_reservation.delete
  end
  puts "Done!"
end

