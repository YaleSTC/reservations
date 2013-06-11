module BlackOutsHelper
  def blackout_errors
    start_black_outs = BlackOut.black_outs_on_date(cart.start_date)
    end_black_outs = BlackOut.black_outs_on_date(cart.due_date)
    
    messages = [messages_for_black_outs(start_black_outs, "start") + messages_for_black_outs(end_black_outs, "end")].uniq.join("\n")
    if messages.present?
      if flash[:error]
        flash[:error] += messages
      else
        flash[:error] = messages
      end
    end
  end

  def messages_for_black_outs(black_outs, date_type)
    messages = []
    black_outs.each do |bo|
      messages << bo.notice + ((bo.black_out_type == "hard") ? " Please choose a different #{date_type} date in your Cart." : "")
    end
    return messages
  end
end