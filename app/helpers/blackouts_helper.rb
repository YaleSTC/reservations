module BlackoutsHelper
  def blackout_errors
    start_blackouts = Blackout.for_date(cart.start_date)
    end_blackouts = Blackout.for_date(cart.due_date)

    messages = (blackout_error_messages(start_blackouts, "START") +
                blackout_error_messages(end_blackouts, "END")).uniq.join("\n")

    if messages.present?
      if flash[:error]
        flash[:error] += messages
      else
        flash[:error] = messages
      end
    end
  end

  # creates an array of all blackout messages from BLACKOUTS, and adds
  # a message about choosing a different TYPE date if a given blackout is
  # hard.
  def blackout_error_messages(blackouts, type)
    messages = []

    blackouts.each do |bo|
      messages << bo.notice
      if bo.blackout_type == "hard"
        messages << "Please choose a different #{type} DATE in your Cart."
      end
    end

    return messages
  end
end
