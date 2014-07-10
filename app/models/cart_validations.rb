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
    errors << "A reservation cannot start on #{self.start_date.to_date.strftime('%m/%d')}" if Blackout.hard.for_date(self.start_date).count > 0
    errors << "A reservation cannot end on #{self.due_date.to_date.strftime('%m/%d')}" if Blackout.hard.for_date(self.due_date).count > 0

    # no overdue reservations
    errors << "This user has overdue reservations that prevent him/her from creating new ones" if Reservation.for_reserver(self.reserver_id).overdue.count > 0
    return errors
  end

  def validate_items
    errors = []
    relevant = Reservation.for_reserver(self.reserver_id).not_returned.includes(:equipment_model).all
    category = Hash.new

    # get hash of model objects and quantities
    models = self.get_items

    # check max model count for each day in the range
    # while simultaneously building a hash of category_ids => quantity
    models.each do |model, quantity|
      max_models = model.maximum_per_user

      self.start_date.to_date.upto(self.due_date.to_date) do |d|
        if count_for_date_and_model(d,model,relevant) + quantity > max_models
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
        if count_for_date_and_category(d,cat.id,relevant) + q > max_cat
          errors << "Cannot reserve more than #{max_cat} #{cat.name.pluralize}"
          break
        end
      end
    end

    return errors
  end

  def validate_dates_and_items
    # lots of queries :(
    #
    puts 'begin validate dates and items!'
    user_reservations = Reservation.for_reserver(self.reserver_id).checked_out.all
    errors = []
    models = self.get_items

    models.each do |model, quantity|

      # check availability, lots of queries from num_available
      errors << "That many #{model.name.pluralize} is not available for the given time range" if model.num_available(self.start_date, self.due_date) < quantity

      # check maximum checkout length: call to .category is 1 query
      max_length = model.category.max_checkout_length
      max_length = Float::INFINITY if max_length == 'unrestricted'
      errors << "#{model.name.titleize} can only be reserved for #{max_length} days" if self.duration > max_length

      # if a reservation should be renewed instead of checked out, 0 queries
      renew_errors = validate_should_be_renewed(user_reservations,model,self.start_date)
      errors << renew_errors if renew_errors
    end
    return errors
  end

  def validate_all
    errors = validate_dates
    errors.concat(validate_items.to_a).concat(validate_dates_and_items.to_a)
    return errors
  end


  ### HELPER METHODS TO AVOID DB CALLS ###
  def validate_should_be_renewed(user_reservations,model,start_date)
    # takes an array of user reservations, a model, and a start_date.
    # if the user reservations array has a reservation for the model that
    # is due on the passed in start date, return an error message
    #
    # 0 queries, except for is_eligible_for_renew

    user_reservations.each do |r|
      if r.equipment_model_id == model.id && r.due_date == start_date && r.is_eligible_for_renew?
        return "#{model.name.titleize} should be renewed instead of re-checked out"
      end
    end
    return nil

  end

  def count_for_date_and_model(date,model,reservations)
    ## takes an array of reservations and returns the number on the
    # given day that match the given model. Do not use scopes to replace
    # this method because it is important that only one DB call is made
    # at the beginning of validate_items to gather the appropriate
    # reservations
    #
    # all arguments should be loaded into memory already. Do not call
    # .id on reservations since that triggers another DB call
    #
    # 0 queries

    count = 0
    reservations.each do |r|
      count += 1 if r.equipment_model_id == model.id && r.start_date <= date && r.due_date >= date
    end
    return count
  end

  def count_for_date_and_category(date,category_id,reservations)
    # see comments for count_for_date_and_model method
    # this is the same but for categories
    # unfortunately extra DB calls are needed because categories are not
    # directly stored in reservation objects :(
    #
    # O(N) queries, minimized by asking for dates first. In practice should not
    # be very many unless the user has a ton of reservations

    count = 0
    reservations.each do |r|
      count += 1 if r.start_date <= date && r.due_date >= date && r.equipment_model.category_id == category_id
    end
    return count
  end


end
