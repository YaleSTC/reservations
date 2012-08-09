module BlackOutsHelper
  def blackout_errors
    if (a = BlackOut.date_is_blacked_out(cart.start_date)) && (b = BlackOut.date_is_blacked_out(cart.due_date))
      if a == b
        flash[:error] = a.notice + ((a.black_out_type == "hard") ? " Please choose different start and end dates in your Cart." : "")
      else
        flash[:error] = a.notice + " " + b.notice + ((a.black_out_type == "hard" || (b.black_out_type == "hard")) ? " Please choose a different start or end date in your Cart." : "")
      end
    elsif (a = BlackOut.date_is_blacked_out(cart.start_date))
      flash[:error] = a.notice + ((a.black_out_type == "hard") ? " Please choose a different start date in your Cart." : "")
    elsif (a = BlackOut.date_is_blacked_out(cart.due_date))
      flash[:error] = a.notice + ((a.black_out_type == "hard") ? " Please choose a different end date in your Cart." : "")
    end
  end
end