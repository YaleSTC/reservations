class ReportsController < ApplicationController
  # before_filter :require_admin
  def index
    @start_date = Date.today.beginning_of_year
    @end_date = Date.today
    #need some kind of admin priveleges before hand...
    users = [current_user]
    
    # res_set = Reservation.starts_on_days(@start_date,@end_date).reserver_is_in(users)
    res_set = Reservation.starts_on_days(@start_date,@end_date)
     
    res_counts = {}
    res_counts[:reserved]    = res_set.reserved.count
    res_counts[:checked_out] = res_set.checked_out.count
    res_counts[:overdue]     = res_set.overdue.count
    res_counts[:returned]    = res_set.returned.count
    res_counts[:missed]      = res_set.missed.count
    res_counts[:upcoming]    = res_set.upcoming.count
    @res_counts = res_counts
    # scopes.each do |scope|
    #       res_counts[scope] = res_set.method(scope).call.count
    #     end
    
    #durations
    
  end
  
end