module ReservationValidations

  ## Validations ##

  # ------- Hard Validations (ActiveRecord) ------------#
  # Adds an error if the validation fails

  # Checks that reservation start date is before end dates
  def start_date_before_due_date?
    return unless start_date && due_date
    if due_date < start_date
      errors.add(:base, "Reservation start date must be before due date.\n")
    end
  end

  # Checks that the equipment_object is of type equipment_model
  def matched_object_and_model?
    return unless equipment_object
    return unless equipment_model
    if equipment_object.equipment_model != equipment_model
      errors.add(:base, equipment_object.name + " must be of type " + equipment_model.name + ".\n")
    end
  end

  # Checks that the equipment model is available from start date to due date
  def available?
    return if self.status != 'reserved'
    return unless equipment_model
    if equipment_model.num_available(start_date, due_date) <= 0
      errors.add(:base, equipment_model.name + " is not available for the full time period requested.\n")
    end
  end

  # Checks that reservation is not in the past
  # Does not run on checked out, checked in, overdue, or missed Reservations
  def not_in_past?
    unless due_date >= Date.today
      errors.add(:base, "Cannot create reservation in the past")
    end
  end

  # Checks that the reservation is not renewable
  def not_renewable?
    Reservation.for_reserver(reserver)
      .checked_out.for_eq_model(self.equipment_model).each do |res|
      if res.due_date.to_date == self.start_date.to_date && res.is_eligible_for_renew?
        return false
      end
    end
    return true
  end

  # Checks that the reservation is not longer than the max checkout length
  def duration_allowed?
    max_duration = equipment_model.category.maximum_checkout_length
    return true if max_duration == "unrestricted" || (self.checked_in)
    self.duration <= max_duration
  end

  # Checks that start date is not a black out date
  def start_date_is_not_blackout?
    !Blackout.hard_blackout_exists_on_date(start_date)
  end

  # Checks that due date is not a black out date
  def due_date_is_not_blackout?
    !Blackout.hard_blackout_exists_on_date(due_date)
  end

  ## For single or multiple reservations

  # Checks that the number of equipment models that a user has reserved
  # is less than the equipment model maximum
  def quantity_eq_model_allowed?(res_array = [])
    max = equipment_model.maximum_per_user
    return true if max == "unrestricted"
    # count number of models for given reservation
    # and reserver's active reservations,
    # excluding those that don't overlap
    reservations = reserver.reservations.active + res_array
    same_model_count(get_overlapping_reservations(reservations)) <= max
  end


  # Checks that the number of categories that a user has reserved
  # is less than the max
  def quantity_cat_allowed?(res_array = [])
    max = equipment_model.category.maximum_per_user
    return true if max == "unrestricted"
    # count number of categories for given reservation
    # and reserver's active reservations
    # excluding those that don't overlap
    reservations = reserver.reservations.active + res_array
    same_category_count(get_overlapping_reservations(reservations)) <= max
  end


  ## Validation helpers##

  # Returns the number of reservations in the array of reservations it is passed
  # that have the same equipment model as the reservation count is called on
  # Assumes that self is in the array of reservations/does not include self
  # Assumes that all reservations have same start and end date as self
  def same_model_count(reservations)
    count = 0
    reservations.each { |res| count += 1 if (res.equipment_model == self.equipment_model) }
    count
  end

  def same_category_count(reservations)
    count = 0
    reservations.each { |res| count += 1 if res.equipment_model.category == self.equipment_model.category }
    count
  end

  def overlaps_with?(other_res)
    start_overlaps = (self.start_date >= other_res.start_date && self.start_date <= other_res.due_date)
    end_overlaps = (self.due_date >= other_res.start_date && self.due_date <= other_res.due_date)
    return true if start_overlaps || end_overlaps
  end

  def get_overlapping_reservations(reservations)
    #duplicate passed in array so we don't modify it for the next round of validations
    reservations = reservations.dup
    reservations << self
    #include all reservations made by user
    reservations.concat(reserver.reservations)
    reservations.uniq!
    reservations.select{ |res| res.overlaps_with?(self) && (res.checked_in == nil) }
  end


end
