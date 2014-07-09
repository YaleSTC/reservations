module CartValidations

  # These validation methods each run several validations within them
  # for the sake of speed and query-saving. They are separated in 3 methods
  # so that the cart doesn't have to validate items when only the dates are
  # changed and vice versa. Each method returns an array of error messages
  #
  #
  # Validate Dates (when dates are changed)
  # ## start, end not on a blackout date
  # ## user has no overdue (reserver is included in the date form)
  #
  # Validate Items (when items are added/removed)
  # ## user doesn't have too many of each equipment model
  # ## or each category
  #
  # Validate Dates and Items
  # ## items are all available for the date range
  # ## the duration of the date range is short enough
  # ## none of the items should be renewed instead of re-reserved
  #
  # Validate All
  # ## just runs everything


  def validate_dates
    errors = []

    # blackouts
    errors << "A reservation cannot start on #{self.start_date.to_date}" if Blackout.hard.for_date(self.start_date).count > 0
    errors << "A reservation cannot end on #{self.due_date.to_date}" if Blackout.hard.for_date(self.due_date).count > 0

    # no overdue reservations
    errors << "This user has overdue reservations that prevent him/her from creating new ones" if Reservation.for_reserver(self.reserver_id).overdue.count > 0
    return errors
  end

  def validate_items
    errors = []
    relevant = Reservation.for_reserver(self.reserver_id).not_returned
    category = Hash.new

    # get hash of model objects and quantities
    models = self.get_items

    # check max model count for each day in the range
    # while simultaneously building a hash of category => quantity
    models.each do |model, quantity|
      max_models = model.maximum_per_user
      self.start_date.to_date.upto(self.due_date.to_date) do |d|
        if relevant.overlaps_with_date(d).for_eq_model(model).count + quantity > max_models
          errors << "Cannot reserve more than #{max_models} #{model.name.pluralize}"
          break
        end
      end

      if category.include?(model.category)
        category[model.category] += quantity
      else
        category[model.category] = quantity
      end

    end

    # similarly check category maxes using a similar method
    category.each do |cat, q|
      max_cat = cat.maximum_per_user
      self.start_date.to_date.upto(self.due_date.to_date) do |d|
        count = 0
        relevant.overlaps_with_date(d).each do |r|

          count += 1 if r.equipment_model.category == cat
        end
        if count + q > max_cat
          errors << "Cannot reserve more than #{max_cat} #{cat.name.pluralize}"
          break
        end
      end
    end

    return errors
  end

  def validate_dates_and_items
    user_reservations = Reservation.for_reserver(self.reserver_id).checked_out
    errors = []
    models = self.get_items
    models.each do |model, quantity|

      # check availability
      errors << "#{model.name.titleize} is not available for the given time range" if model.num_available(self.start_date, self.due_date) < quantity

      # check maximum checkout length
      max_length = model.category.max_checkout_length
      max_length = Float::INFINITY if max_length == 'unrestricted'
      errors << "#{model.name.titleize} can only be reserved for #{max_length} days" if self.duration > max_length

      # if a reservation should be renewed instead of checked out
      user_reservations.for_eq_model(model).each do |r|
        errors << "#{model.name.titleize} should be renewed instead of re-checked out"  if r.due_date == self.start_date && r.is_eligible_for_renew?
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
