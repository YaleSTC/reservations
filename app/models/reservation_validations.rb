module ReservationValidations

  def self.included(base)
    base.belongs_to :equipment_model
    base.belongs_to :reserver, :class_name => 'User'
    base.attr_accessible :reserver, :reserver_id, :start_date, :due_date,
                         :equipment_model_id
  end

  ## Validations ##

  ## For individual reservations only
  # Checks if the user has any overdue reservations
  # Same for CartReservations and Reservations
  #TODO: admin override
  def no_overdue_reservations?
    if Reservation.overdue_reservations?(reserver)
      errors.add(:base, reserver.name + " has overdue reservations that prevent new ones from being created")
      return false
    end
    return true
  end

  # Checks that reservation start date is before end dates
  # Same for CartReservations and Reservations
  def start_date_before_due_date?
    if due_date < start_date
      errors.add(:base, "Reservations cannot be made in the past")
      return false
    end
    return true
  end

  # Checks that reservation is not in the past
  # Does not run on checked out, checked in, overdue, or missed Reservations
  def not_in_past?
    #return true if self.class == Reservation && self.status != 'reserved'
    if (start_date < Date.today) || (due_date < Date.today)
      errors.add(:base, "Reservations start dates must be before due dates")
      return false
    end
    return true
  end

  # Checks that the reservation has an equipment model
  def not_empty?
    if equipment_model.nil?
      errors.add(:base, "Reservations must have an associated equipment model")
      return false
    end
    return true
  end

  # Checks that the equipment_object is of type equipment_model
  def matched_object_and_model?
    if self.class == Reservation && self.equipment_model && self.equipment_object
      if equipment_object.equipment_model != equipment_model
        errors.add(:base, equipment_object.name + " must be of type " + equipment_model.name)
        return false
      end
    end
    return true
  end

  # Checks that the reservation is not renewable
  #TODO: allow admin override
  def not_renewable?
    return true unless self.class == CartReservation || self.status == "reserved"
    reserver.reservations.each do |res|
      if res.equipment_model == self.equipment_model && res.due_date.to_date == self.start_date.to_date && res.is_eligible_for_renew?
        errors.add(:base, res.equipment_model.name + " should be renewed instead of re-checked out")
        return false
      end
    end
    return true
  end

  # Checks that the reservation is not longer than the max checkout length
  #TODO: admin override
  def duration_allowed?
    duration = due_date.to_date - start_date.to_date + 1
    cat_duration = equipment_model.category.maximum_checkout_length
    return true if cat_duration == "unrestricted"
    if duration > cat_duration
      errors.add(:base, "Duration of " + equipment_model.name + " reservation must be less than " + equipment_model.category.maximum_checkout_length.to_s)
      return false
    end
    return true
  end

  # Checks that start date is not a black out date
  def start_date_is_not_blackout?
    if (a = BlackOut.date_is_blacked_out(start_date)) && a.black_out_type_is_hard
      errors.add(:base, "A reservation cannot start on " + start_date.strftime('%m/%d') + " because equipment cannot be picked up on that date")
      return false
    end
    return true
  end

  # Checks that due date is not a black out date
  def due_date_is_not_blackout?
    if (a = BlackOut.date_is_blacked_out(due_date)) && a.black_out_type_is_hard
      errors.add(:base, "A reservation cannot end on " + due_date.strftime('%m/%d') + " because equipment cannot be returned on that date")
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
      errors.add(:base, equipment_model.name + " is not available for the full time period requested")
      return false
    end
    return true
  end

  # Checks that the number of equipment models that a user has reserved and in
  # the array of reservations is less than the equipment model maximum
  #TODO: admin override
  def quantity_eq_model_allowed?(reservations = [])
    max = equipment_model.maximum_per_user
    return true if max == "unrestricted"

    #duplicate passed in array so we don't modify it for the next round of validations
    all_res = reservations.dup
    all_res << self
    #include all reservations made by user
    all_res.concat(reserver.reservations)
    all_res.uniq!
    
    #exclude reservations that don't overlap
    #TODO: Optimize into a finder scope
    overlapping_res = all_res.select{ |res| res.overlaps_with?(self) && (res.class == CartReservation || res.checked_in == nil) }
    
    model_count = same_model_count(overlapping_res)
    if model_count > max
      errors.add(:base, "Quantity of " + equipment_model.name.pluralize + " must not exceed " + equipment_model.maximum_per_user.to_s)
      return false
    end
    return true
  end

  # Checks that the number of items that the user has reserved and in the
  # array of reservations does not exceed the maximum in the category of the
  # reservation it is called on
  #TODO: admin override
  def quantity_cat_allowed?(reservations = [])
    max = equipment_model.category.maximum_per_user
    return true if max == "unrestricted"
    
    #duplicate passed in array so we don't modify it for the next round of validations
    all_res = reservations.dup
    all_res << self
    #include all reservations made by user
    all_res.concat(reserver.reservations)
    all_res.uniq!
    
    #exclude reservations that don't overlap
    #TODO: Optimize into a finder scope
    overlapping_res = all_res.select{ |res| res.overlaps_with?(self) && (res.class == CartReservation || res.checked_in == nil) }
    
    cat_count = same_category_count(overlapping_res)
    if cat_count > max
      errors.add(:base, "Quantity of " + equipment_model.category.name.pluralize + " must not exceed " + equipment_model.category.maximum_per_user.to_s)
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


end
