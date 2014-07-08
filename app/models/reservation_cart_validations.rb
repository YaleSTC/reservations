  def validate_dates
    # run on date change
    errors = []
    # blackouts not on date
    errors << "blackout exists on start date" if Blackout.hard_blackout_exists_on_date(@start_date)
    errors << "blackout exists on end date" if Blackout.hard_blackout_exists_on_date(@due_date)
    errors << "overdue reservations" if Reservation.for_reserver(@reserver_id).overdue.count > 0
    # for some reason reserver is submitted at the same time as dates
    return errors
  end

  def validate_items(res_array = [])
    unless res_array.empty?
      # reservation call
      # convert res array to cart style items hash
      # note this means that the cart dates are "locked down",
      # as in it will be very difficult to create multiple reservations
      # with different dates out of a single 'cart'
    end
    errors = []
    relevant = Reservation.for_reserver(@reserver_id).active
    @items.each do |em_id, quantity|

    end
    #under_max_model_count?

    #under_max_category_count?
    errors << 'maybe you have an error with items? idk'
    return errors
  end

  def validate_dates_and_items
    # validations that run on both item and date changes
    # available
    # duration
    # not renewable
  end

  def validate_all
    errors = validate_dates
    errors.concat(validate_items.to_a).concat(validate_dates_and_items.to_a)
    return errors
  end

