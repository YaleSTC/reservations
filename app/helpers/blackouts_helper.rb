module BlackoutsHelper
  def blackout_errors
    start_blackouts = Blackout.blackouts_on_date(cart.start_date)
    end_blackouts = Blackout.blackouts_on_date(cart.due_date)

    messages = [messages_for_blackouts(start_blackouts, "start") + messages_for_blackouts(end_blackouts, "end")].uniq.join("\n")
    if messages.present?
      if flash[:error]
        flash[:error] += messages
      else
        flash[:error] = messages
      end
    end
  end

  def messages_for_blackouts(blackouts, date_type)
    messages = []
    blackouts.each do |bo|
      messages << bo.notice + ((bo.blackout_type == "hard") ? " Please choose a different #{date_type} date in your Cart." : "")
    end
    return messages
  end
end