class ReportsController < ApplicationController
  # before_filter :require_admin
  def index
    
    #need some kind of admin priveleges before hand...
    users = [current_user]
    
    res_stats = {}
    res_stats[:reserved]    = Reservation.reserved.count
    res_stats[:checked_out] = Reservation.checked_out.count
    res_stats[:overdue]     = Reservation.overdue.count
    res_stats[:returned]    = Reservation.returned.count
    res_stats[:missed]      = Reservation.missed.count
    res_stats[:upcoming]    = Reservation.upcoming.count
    
    
  end
  
end