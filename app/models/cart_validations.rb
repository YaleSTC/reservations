module CartValidations
  def validate_dates
    # run on date change
    errors = []
    # blackouts not on date
    errors << "blackout exists on start date" if Blackout.hard_blackout_exists_on_date(self.start_date)
    errors << "blackout exists on end date" if Blackout.hard_blackout_exists_on_date(self.due_date)
    errors << "overdue reservations" if Reservation.for_reserver(self.reserver_id).overdue.count > 0
    # for some reason reserver is submitted at the same time as dates
    return errors
  end

  def validate_items
    errors = []
    relevant = Reservation.for_reserver(self.reserver_id).not_returned
    category = Hash.new
    # check if under max model count while simultaneously building a category hash
    self.items.each do |em_id, quantity|
      model = EquipmentModel.find(em_id)
      max_models = model.maximum_per_user
      self.start_date.to_date.upto(self.due_date.to_date) do |d|
        if relevant.overlaps_with_date(d).for_eq_model(model).count + quantity > max_models
          errors << "over max model count"
          break
        end
      end

      if category.include?(model.category)
        category[model.category] += quantity
      else
        category[model.category] = quantity
      end

    end

    # check if under max category count
    category.each do |cat, q|
      max_cat = cat.maximum_per_user
      self.start_date.to_date.upto(self.due_date.to_date) do |d|
        count = 0
        relevant.overlaps_with_date(d).each do |r|

          count += 1 if r.equipment_model.category == cat
        end
        if count + q > max_cat
          errors << "over max category count"
          break
        end
      end
    end
    return errors

  end

  def validate_dates_and_items
    # validations that run on both item and date changes

    user_reservations = Reservation.for_reserver(self.reserver_id).checked_out
    errors = []
    self.items.each do |item, quantity|
      model = EquipmentModel.find(item)

      # check availability
      errors << "not available" if model.num_available(self.start_date, self.due_date) < quantity

      # check maximum checkout length
      max_length = model.category.max_checkout_length
      max_length = Float::INFINTIY if max_length == 'unrestricted'
      errors << "too long checkout length" if self.duration > max_length

      user_reservations.for_eq_model(model).each do |r|
        errors << "renew, man"  if r.due_date == self.start_date && r.is_eligible_for_renew?
      end
    end
    return errors
  end

  def validate_all
    errors = validate_dates
    errors.concat(validate_items.to_a).concat(validate_dates_and_items.to_a)
    return errors
  end
end
