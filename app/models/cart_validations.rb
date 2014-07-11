module CartValidations

  # These validation methods were carefully written to use as few database
  # queries as possible. Often it seems that a scope could be used but
  # it is important to remember that Rails lazy-loads the database calls
  #
  def validate_all
    # 2 queries for every equipment model in the cart because of num_available
    # plus about 8 extra
    errors = []
    errors += check_start_date_blackout
    errors += check_due_date_blackout
    errors += check_overdue_reservations
    errors += check_max_items

    user_reservations = Reservation.for_reserver(self.reserver_id).not_returned.all
    models = self.get_items
    source_res = Reservation.not_returned.where(equipment_model_id: self.items.keys).reserved_in_date_range(self.start_date,self.due_date).all

    models.each do |model, quantity|
      errors += check_availability(model,quantity,source_res)
      errors += check_duration(model)
      errors += check_should_be_renewed(user_reservations,model,self.start_date)
    end
    return errors.uniq.reject{ |a| a.blank? }
  end

  def check_start_date_blackout
    # check that the start date is not on a blackout date
    # 1 query
    errors = []
    if Blackout.hard.for_date(self.start_date).count > 0
      errors << "#{Blackout.get_notices_for_date(self.start_date,:hard)} (a reservation cannot start on #{self.start_date.to_date.strftime('%m/%d')})"
    end
    errors
  end

  def check_due_date_blackout
    # check that the due date is not on a blackout date
    # 1 query
    errors = []
    if Blackout.hard.for_date(self.due_date).count > 1
      errors << "#{Blackout.get_notices_for_date(self.due_date,:hard)} (a reservation cannot end on #{self.due_date.to_date.strftime('%m/%d')})"
    end
    errors
  end

  def check_overdue_reservations
    # check that the reserver has no overdue reservations
    # 1 query
    errors = []
    if Reservation.for_reserver(self.reserver_id).overdue.count > 0
      errors << "This user has overdue reservations that prevent him/her from creating new ones"
    end
    errors
  end

  def check_max_items
    # check that the cart items would not cause the reserver to have
    # more than the max allowed number of the same equipment model
    # or the max allowed number of the same category item
    # on any given date
    #
    # 4 queries
    errors = []
    relevant = Reservation.for_reserver(self.reserver_id).not_returned.includes(:equipment_model).all
    category = Hash.new

    # get hash of model objects and quantities
    # remember that the get_items method eager loads
    # the categories
    models = self.get_items

    # check max model count for each day in the range
    # while simultaneously building a hash of category => quantity
    models.each do |model, quantity|
      max_models = model.maximum_per_user

      self.start_date.to_date.upto(self.due_date.to_date) do |d|
        if Reservation.number_for_model_on_date(d,model.id,relevant) + quantity > max_models
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
        if Reservation.number_for_category_on_date(d,cat.id,relevant) + q > max_cat
          errors << "Cannot reserve more than #{max_cat} #{cat.name.pluralize}"
          break
        end
      end
    end

    errors
  end

  def check_availability(model = EquipmentModel.find(self.items.keys.first),
                         quantity=1,
                         source_res=Reservation.for_eq_model(self).not_returned.all)
    # checks that the model is available for the given quantity
    # given the existence of the source_reservations
    #
    # if called with no arguments, automatically assumes it is
    # checking for a cart with only 1 argument with quantity 1
    # which is a common case when checking availability of a single
    # reservation (eg, reservation.to_cart.check_availability)
    #
    # to check the contents of a whole cart you need to iterate over
    # its items hash to pass in the models and quantities
    #
    # the advantage is that source_res is constant and requires no
    # additional DB calls. unfortunately num-available still requires
    # 2 queries to establish the max number of available items
    #
    # 2 queries

    errors = []
    if model.num_available_from_source(self.start_date, self.due_date,source_res) < quantity
      errors << "That many #{model.name.pluralize} are not available for the given time range"
    end
    errors
  end

  def check_duration(model = EquipmentModel.find(self.items.keys.first))
    # check that the duration of the cart does not exceed the
    # specified maximum duration for any category in the cart
    #
    # arguments behavior is similar to check_availability
    #
    # 0 queries if categories have been eager loaded
    errors = []
    max_length = model.category.max_checkout_length
    max_length = Float::INFINITY if max_length == 'unrestricted'
    if self.duration > max_length
      errors << "#{model.name.titleize} can only be reserved for #{max_length} days"
    end
    errors
  end

  def check_should_be_renewed(user_reservations = Reservations.for_reserver(self.reserver).not_returned,
                              model = EquipmentModel.find(self.items.keys.first),
                              start_date = self.start_date)
    # if the user reservations array has a reservation for the model that
    # is due on the passed in start date, return an error message
    #
    # argument behavior is similar to check_availability
    #
    # 0 queries, except for is_eligible_for_renew
    errors = []
    user_reservations.each do |r|
      if r.equipment_model_id == model.id && r.due_date == start_date && r.is_eligible_for_renew?
        errors << "#{model.name.titleize} should be renewed instead of re-checked out"
      end
    end
    errors
  end

end
