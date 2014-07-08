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

  def validate_items
    errors = []
    relevant = Reservation.for_reserver(@reserver_id).not_returned

    category = Hash.new
    # check if under max model count while simultaneously building a category hash
    @items.each do |em_id, quantity|
      model = EquipmentModel.find(em_id)
      max_models = model.maximum_per_user
      @start_date.upto(@due_date) do |d|
        errors << "over max model count" if relevant.overlaps_with_date(d).for_eq_model(model).count + quantity > max_models
        break
      end

      if category.includes?(model.category)
        category[model.category] += quantity
      else
        category[model.category] = quantity
      end

    end

    # check if under max category count
    category.each do |cat, q|
      max_cat = cat.maximum_per_user
      @start_date.upto(due_date) do |d|
        count = 0
        relevant.overlaps_with_date(d).each do |r|
          count += 1 if r.equipment_model.category == cat
        end
        errors << "over max category count" if count + q > max_cat
        break
      end
    end
    return errors

  end

  def validate_dates_and_items
    # validations that run on both item and date changes

    user_reservations = Reservation.for_reserver(@reserver_id).checked_out
    errors = []
    @items.each do |item, quantity|
      model = EquipmentModel.find(item)
      errors << "not available" if model.num_available(@start_date, @end_date) < quantity
      errors << "too long checkout length" if cart.duration > model.max_checkout_length
      user_reservations.for_eq_model(model).each do |r|
        errors << "renew, man"  if r.due_date == @start_date && r.is_eligible_for_renew?
      end
    end
    return errors
  end

  def validate_all
    errors = validate_dates
    errors.concat(validate_items.to_a).concat(validate_dates_and_items.to_a)
    return errors
  end

