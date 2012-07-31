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
      errors.add(:base, "User has overdue reservations")
      return false
    end
    return true
  end

  # Checks that reservation start date is before end dates
  # Same for CartReservations and Reservations
  def start_date_before_due_date?
    if due_date < start_date
      errors.add(:base, "Reservation start date must be before due date")
      return false
    end
    return true
  end

  # Checks that reservation is not in the past
  # Does not run on checked out, checked in, overdue, or missed Reservations
  def not_in_past?
    return true if self.class == Reservation && self.status != 'reserved'
    if (start_date < Date.today) || (due_date < Date.today)
      errors.add(:base, "Reservation can't be in past")
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
        errors.add(:base, equipment_object.name + " is not of type " + equipment_model.name)
        return false
      end
    end
    return true
  end

  # Checks that the reservation is not renewable
  #TODO: should it be res.due_date.to_date >= self.start_date.to_date?
  #TODO: allow admin override
  def not_renewable?
    reserver.reservations_array.each do |res|
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
      errors.add(:base, "duration problem with " + equipment_model.name)
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
    if equipment_model.available?(start_date, due_date) < eq_objects_needed
      errors.add(:base, "availablity problem with " + equipment_model.name)
      return false
    end
    return true
  end

  # Checks that the number of equipment models that a user has reservered and in
  # the array of reservations is less than the equipment model maximum
  #TODO: admin override
  def quantity_eq_model_allowed?(reservations = [])
    max = equipment_model.maximum_per_user
    return true if max == "unrestricted"
    all_res = reservations.dup
    all_res << self
    all_res.concat(reserver.reservations_array)
    all_res.uniq!
    num_reservations = same_model_count(all_res)
    if num_reservations > max
      errors.add(:base, "quantity equipment model problem with " + equipment_model.name)
      return false
    end
    return true
  end

  # Checks that the number of items that the user has reservered and in the
  # array of reservations does not exceed the maximum in the category of the
  # reservation it is called on
  #TODO: admin override
  def quantity_cat_allowed?(reservations = [])
    max = equipment_model.category.maximum_per_user
    return true if max == "unrestricted"
    all_res = reservations.dup
    all_res << self
    all_res.concat(reserver.reservations_array)
    all_res.uniq!
    cat_count = 0
    all_res.each { |res| cat_count += 1 if res.equipment_model.category == self.equipment_model.category }
    if cat_count > max
      errors.add(:base, "quantity category problem with " + equipment_model.category.name)
      return false
    end
    return true
  end


  ## Validation helper##

  # Returns the number of reservations in the array of reservations it is passed
  # that have the same equipment model as the reservation count is called on
  # Assumes that self is in the array of reservations/does not include self
  # Assumes that all reservations have same start and end date as self
  def same_model_count(reservations)
    count = 0
    reservations.each { |res| count += 1 if res.equipment_model == self.equipment_model }
    count
  end
end
