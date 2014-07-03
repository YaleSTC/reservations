module ReservationValidations

  ## Validations ##

  ## For individual reservations only
  # Checks if the user has any overdue reservations
  # Same for CartReservations and Reservations
  #TODO: admin override
  def no_overdue_reservations?
    if Reservation.overdue_reservations?(reserver)
      errors.add(:base, reserver.name + " has overdue reservations that prevent new ones from being created.\n")
      return false
    end
    return true
  end

  # Checks that reservation start date is before end dates
  # Same for CartReservations and Reservations
  def start_date_before_due_date?
    if due_date < start_date
      errors.add(:base, "Reservation start date must be before due date.\n")
      return false
    end
    return true
  end

  # Checks that reservation is not in the past
  # Does not run on checked out, checked in, overdue, or missed Reservations
  def not_in_past?
    #return true if self.class == Reservation && self.status != 'reserved'
    if (start_date < Date.today) || (due_date < Date.today)
      errors.add(:base, "Reservation cannot be made in the past.\n")
      return false
    end
    return true
  end

  # Checks that the reservation has an equipment model
  def not_empty?
    if equipment_model.nil?
      errors.add(:base, "Reservation must be for a piece of equipment.\n")
      return false
    end
    return true
  end

  # Checks that the equipment_object is of type equipment_model
  def matched_object_and_model?
    if self.class == Reservation && self.equipment_model && self.equipment_object
      if equipment_object.equipment_model != equipment_model
        errors.add(:base, equipment_object.name + " must be of type " + equipment_model.name + ".\n")
        return false
      end
    end
    return true
  end

  # Checks that the reservation is not renewable
  #TODO: allow admin override
  def not_renewable?
    reserver.reservations.each do |res|
      if res.equipment_model == self.equipment_model && res.due_date.to_date == self.start_date.to_date && res.is_eligible_for_renew?
        errors.add(:base, res.equipment_model.name + " should be renewed instead of re-checked out.\n")
        return false
      end
    end
    return true
  end

  # Checks that the reservation is not longer than the max checkout length
  #TODO: admin override
  def duration_allowed?
    max_duration = equipment_model.category.maximum_checkout_length
    if max_duration == "unrestricted" || (self.class == Reservation && self.checked_in)
      return true
    elsif self.duration > max_duration
      errors.add(:base, equipment_model.name + "cannot be reserved for more than " + max_duration.to_s + " days at a time.\n")
      return false
    else
      return true
    end
  end

  # Checks that start date is not a black out date
  def start_date_is_not_blackout?
    if Blackout.hard_blackout_exists_on_date(start_date)
      errors.add(:base, "Reservation cannot start on " + start_date.strftime('%m/%d') + " because equipment cannot be picked up on that date.\n")
      return false
    end
    return true
  end

  # Checks that due date is not a black out date
  def due_date_is_not_blackout?
    if Blackout.hard_blackout_exists_on_date(due_date)
      errors.add(:base, "Reservation cannot end on " + due_date.strftime('%m/%d') + " because equipment cannot be returned on that date.\n")
      return false
    end
    return true
  end

  ## For single or multiple reservations
  # Checks that the equipment model is available from start date to due date
  # Not called on overdue, missed, checked out, or checked in Reservations
  # because this would double count the reservations. all_res is only cart
  # reservations but if there are too many reserved reservations, it will still
  # return false because available? will return less than 0
  def available?(reservations = [])
    return true if self.class == Reservation && self.status != 'reserved'
    all_res = reservations.dup
    all_res << self if self.class != Reservation
    all_res.uniq!
    eq_objects_needed = same_model_count(all_res)
    if equipment_model.num_available(start_date, due_date) < eq_objects_needed
      errors.add(:base, equipment_model.name + " is not available for the full time period requested.\n")
      return false
    end
    return true
  end

  # Checks that the number of equipment models that a user has reserved
  # is less than the equipment model maximum
  def quantity_eq_model_allowed?(res_array = [])
    max = equipment_model.maximum_per_user
    return true if max == "unrestricted"
    # count number of models for given reservation
    # and reserver's active reservations,
    # excluding those that don't overlap
    reservations = reserver.reservations.active + res_array
    if same_model_count(get_overlapping_reservations(reservations)) > max
      errors.add(:base, "Cannot reserve more than " + equipment_model.maximum_per_user.to_s + " " + equipment_model.name.pluralize + ".\n")
      return false
    end
    return true
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
    if same_category_count(get_overlapping_reservations(reservations)) > max
      errors.add(:base, "Cannot reserve more than " + equipment_model.category.maximum_per_user.to_s + " " + equipment_model.category.name.pluralize + ".\n")
      return false
    end
    return true
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
