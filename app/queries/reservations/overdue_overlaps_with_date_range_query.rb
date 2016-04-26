module Reservations
  class OverdueOverlapsWithDateRangeQuery < Reservations::ReservationsQueryBase
    def call(start_date, end_date)
    	# if today is in the date range, then check if the relation is merely overdue today (the flag is enough)
    	# otherwise, just check if the start or end dates overlap with the specified date range
    	if today_in_range(start_date, end_date, Time.zone.today)
    		@relation
    			.where(overdue: true).checked_out
    	else
    		@relation
        	.where('start_date <= ? and due_date >= ?', end_date, start_date)
  		end
    end

    def today_in_range(start_date, end_date, today_date)
    	today_date >= start_date && today_date <= end_date
    end
  end
end
