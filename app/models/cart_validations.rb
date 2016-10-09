# frozen_string_literal: true
# rubocop:disable ModuleLength
module CartValidations
  # These validation methods were carefully written to use as few database
  # queries as possible. Often it seems that a scope could be used but
  # it is important to remember that Rails lazy-loads the database calls
  def validate_all(renew = false) # rubocop:disable AbcSize, MethodLength
    # 2 queries for every equipment model in the cart because of num_available
    # plus about 8 extra
    #
    # if passed with true argument doesn't run validations that should be
    # skipped when validating renewals
    errors = []
    errors += check_banned
    errors += check_consecutive
    errors += check_date_blackout(start_date, 'start')
    errors += check_date_blackout(due_date, 'end')
    errors += check_overdue_reservations unless renew
    errors += check_max_ems
    errors += check_max_cat
    errors += check_cookie_limit

    user_reservations = Reservation.for_reserver(reserver_id).active.all
    models = get_items

    errors += check_requirements(models)

    source_res =
      Reservation.where(equipment_model_id: items.keys)
                 .overlaps_with_date_range(start_date, due_date).active.all

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

  def check_consecutive # rubocop:disable AbcSize
    errors = []
    reserver = User.find_by(id: reserver_id)
    models = get_items.keys
    models.each do |model|
      next unless model.maximum_per_user == 1 && model.maximum_checkout_length
      consecutive =
        Reservation.for_reserver(reserver).for_eq_model(model)
                   .consecutive_with(start_date, due_date)

      consecutive.each do |c|
        next unless c.duration + duration > model.maximum_checkout_length
        errors << "Reserver has a consecutive reservation (#{c.md_link}) "\
          "that exceeds the duration limit for the model #{model.name}."
      end

      next unless consecutive.size > 1 &&
                  duration + consecutive.inject(0) { |a, e| a + e.duration } >
                  model.maximum_checkout_length
      errors << 'Reserver has consecutive reservations that exceeds the '\
        "duration limit for the model #{model.name}."
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

  def check_max_ems
    # check to make sure that the cart's EMs + the current resever's
    # EMs doesn't exceed any limits
    # 1 query

    # get reserver's active reservations
    source = Reservation.active.for_reserver(reserver_id).to_a

    errors = []
    get_items.each do |model, number_in_cart|
      # get highest number of items reserved in date range of cart
      valid = Reservation.number_for_date_range(source, start_date..due_date,
                                                equipment_model_id: model.id,
                                                overdue: false).max
      valid ||= 0
      # count overdue reservations for this eq model
      overdue = source.count { |r| r.equipment_model == model && r.overdue }

      next unless valid + overdue + number_in_cart > model.maximum_per_user

      max = model.maximum_per_user
      errors << "Only #{max} #{model.name.pluralize(max)} "\
        'can be reserved at a time.'
    end
    errors
  end

  def check_max_cat
    # same but for categories. we need to build the counts of the
    # categories ourselves though
    # 2 queries

    cat_hash = get_categories

    source = Reservation.for_reserver(reserver_id).with_categories.active

    # split overdue and non overdue reservations
    overdue, source = source.partition(&:overdue)

    errors = []
    cat_hash.each do |cat, q|
      max = cat.maximum_per_user
      s = source.select { |r| r.equipment_model.category == cat }
      s = Reservation.number_for_date_range(s, start_date..due_date).max
      s ||= 0
      o = overdue.count { |r| r.equipment_model.category == cat }
      next unless s + o + q > max
      errors << "Only #{max} #{cat.name.pluralize(max)} "\
        'can be reserved at a time.'
    end
    errors
  end

  def check_availability(model = EquipmentModel.find(items.keys.first),
                         quantity = 1,
                         source_res =
                           Reservation.for_eq_model(items.keys.first)
                                      .active.all)

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
    max_available = model.num_available(start_date, due_date, source_res)
    return errors unless max_available < quantity
    if max_available == 0
      error = "No #{model.name.pluralize} are"
    else
      error = "Only #{max_available} #{model.name.pluralize(max_available)}" \
      " #{(max_available == 1 ? 'is' : 'are')}"
    end
    error += ' available for the given time range.'
    errors << error
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
    .for_reserver(reserver).active,
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
