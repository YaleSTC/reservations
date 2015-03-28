module CartValidations
  # These validation methods were carefully written to use as few database
  # queries as possible. Often it seems that a scope could be used but
  # it is important to remember that Rails lazy-loads the database calls
  #
  def validate_all(renew = false) # rubocop:disable AbcSize, MethodLength
    # 2 queries for every equipment model in the cart because of num_available
    # plus about 8 extra
    #
    # if passed with true argument doesn't run validations that should be
    # skipped when validating renewals
    errors = []
    errors += check_banned
    errors += check_date_blackout(start_date, 'start')
    errors += check_date_blackout(due_date, 'end')
    errors += check_overdue_reservations unless renew
    errors += check_max_ems
    errors += check_max_cat
    errors += check_cookie_limit

    user_reservations = Reservation.for_reserver(reserver_id).not_returned.all
    models = get_items

    errors += check_requirements(models)

    source_res =
      Reservation.not_returned
      .where(equipment_model_id: items.keys)
      .reserved_in_date_range(start_date, due_date).all

    models.each do |model, quantity|
      errors += check_availability(model, quantity, source_res)
      errors += check_duration(model) unless renew
      errors += check_should_be_renewed(user_reservations, model, start_date)
    end
    errors.uniq.reject(&:blank?)
  end

  def check_banned
    errors = []
    reserver = User.find_by(id: reserver_id)
    if reserver && reserver.role == 'banned'
      errors << 'The reserver is banned and cannot reserve additional '\
        'equipment.'
    end
    errors
  end

  def check_date_blackout(date, verb)
    # check that the start date is not on a blackout date
    # 1 query
    errors = []
    if Blackout.hard.for_date(date).count > 0
      errors << "#{Blackout.get_notices_for_date(date, :hard)} "\
        "(a reservation cannot #{verb} on "\
        "#{date.to_date.strftime('%m/%d')})."
    end
    errors
  end

  def check_overdue_reservations
    # check that the reserver has no overdue reservations
    # 1 query
    errors = []
    if Reservation.for_reserver(reserver_id).overdue.count > 0
      errors << 'This user has overdue reservations that prevent him/her '\
        'from creating new ones.'
    end
    errors
  end

  def check_cookie_limit
    # checks the total number of models in the cart to prevent cookie
    # overflow, the limit is somewhat arbitrarily set to 100 based on an
    # estimated actual limit of >350 (see issue #880)
    cookie_limit = 100
    errors = []
    if items.count > cookie_limit
      errors << "You cannot add more than #{cookie_limit} models to the cart."
    end
    errors
  end

  def check_max_items(count_hash, relevant, count_method)
    # generic method for making sure the count_hash doesn't
    # contain more than the item max when taking into account
    # the relevant reservations

    errors = []
    count_hash.each do |item, q|
      max = item.maximum_per_user

      start_date.upto(due_date) do |d|
        unless Reservation.send(count_method, d, item.id, relevant) + q > max
          next
        end
        errors << "Only #{max} #{item.name.pluralize} "\
          'can be reserved at a time.'
      end
    end
    errors
  end

  def check_max_ems
    # check to make sure that the cart's EMs + the current resever's
    # EMs doesn't exceed any limits

    count_hash = get_items
    relevant = Reservation.for_reserver(reserver_id).not_returned
               .includes(:equipment_model).all
    check_max_items(count_hash, relevant, :number_for_model_on_date)
  end

  def check_max_cat
    # same but for categories. we need to build the counts of the
    # categories ourselves though

    cat_hash = {}
    ems = EquipmentModel.where(id: items.keys).includes(:category)
    items.each_with_index do |(_em_id, q), index|
      cat_hash[ems[index].category] ||= 0
      cat_hash[ems[index].category] += q
    end
    relevant = Reservation.for_reserver(reserver_id).not_returned
               .with_categories.all
    check_max_items(cat_hash, relevant, :number_for_category_on_date)
  end

  def check_availability(model = EquipmentModel.find(items.keys.first),
                         quantity = 1,
                         source_res = Reservation.for_eq_model(self)
                           .not_returned.all)

    # checks that the model is available for the given quantity given the
    # existence of the source_reservations
    #
    # if called with no arguments, automatically assumes it is checking for
    # a cart with only 1 argument with quantity 1 which is a common case when
    # checking availability of a single reservation (eg,
    # reservation.to_cart.check_availability)
    #
    # to check the contents of a whole cart you need to iterate over its
    # items hash to pass in the models and quantities
    #
    # the advantage is that source_res is constant and requires no additional
    # DB calls. unfortunately num-available still requires 2 queries to
    # establish the max number of available items
    #
    # 2 queries

    errors = []
    if model.num_available_from_source(start_date, due_date,
                                       source_res) < quantity
      errors << "That many #{model.name.pluralize} are not available for "\
        'the given time range.'
    end
    errors
  end

  def check_duration(model = EquipmentModel.find(items.keys.first))
    # check that the duration of the cart does not exceed the
    # specified maximum duration for any category in the cart
    #
    # arguments behavior is similar to check_availability
    #
    # 0 queries if categories have been eager loaded
    errors = []
    max_length = model.maximum_checkout_length
    if duration > max_length
      errors << "#{model.name.titleize} can only be reserved for "\
        "#{max_length} days."
    end
    errors
  end

  def check_should_be_renewed(user_reservations = Reservations
    .for_reserver(reserver).not_returned,
                              model = EquipmentModel.find(items.keys.first),
                              start_date = self.start_date)
    # if the user reservations array has a reservation for the model that
    # is due on the passed in start date, return an error message
    #
    # argument behavior is similar to check_availability
    #
    # 0 queries, except for is_eligible_for_renew
    errors = []
    user_reservations.each do |r|
      next unless r.equipment_model_id == model.id &&
                  r.due_date == start_date &&
                  r.eligible_for_renew?
      errors << "#{model.name.titleize} should be renewed instead of "\
          're-checked out.'
    end
    errors
  end

  def check_requirements(items = get_items)
    # check that the reserver specified in the cart has all the necessary
    # requirements for the equipment models in the cart
    return [] if reserver_id.nil?

    user = User.find(reserver_id)
    user_reqs = user.requirements
    item_reqs = []
    items.each do |em, _q|
      item_reqs += em.requirements
    end
    unfulfilled_reqs = item_reqs.uniq - user_reqs
    return [] if unfulfilled_reqs.blank?
    unfulfilled_req_text = []
    unfulfilled_reqs.each do |r|
      unfulfilled_req_text << r.description
    end
    ["#{user.name} is missing the following certifications: "\
      "#{unfulfilled_req_text.to_sentence}"]
  end
end
