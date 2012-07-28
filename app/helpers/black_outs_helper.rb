module BlackOutsHelper
  def blackout_errors
    if (a = BlackOut.date_is_blacked_out(cart.start_date)) && (b = BlackOut.date_is_blacked_out(cart.due_date))
      if a == b
        flash[:error] = a.notice + " Please choose a different start or end date in your Cart."
      else
        flash[:error] = a.notice + " " + b.notice + " Please choose a different start or end date in your Cart."
      end
    elsif (a = BlackOut.date_is_blacked_out(cart.start_date))
      flash[:error] = a.notice + " Please choose a different start or end date in your Cart."
    elsif (a = BlackOut.date_is_blacked_out(cart.due_date))
      flash[:error] = a.notice + " Please choose a different start or end date in your Cart."
    end
  end

end