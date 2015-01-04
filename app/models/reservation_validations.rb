module ReservationValidations
  ## Validations ##

  # Catch-all validation methods #

  def validate
    # Convert reservation to a cart object and run validations on it
    # For hard validations, use reservation.valid
    to_cart.validate_all
  end

  def validate_renew
    to_cart.validate_all(true)
  end

  # ------- Hard Validations (ActiveRecord) ------------#
  # Adds an error if the validation fails

  def not_empty
    return unless equipment_model.nil?
    errors.add(:base, 'Reservation must be for an object')
  end
  # Checks that reservation start date is before end dates
  def start_date_before_due_date
    return unless start_date && due_date && (due_date < start_date)
    errors.add(:base, "Reservation start date must be before due date.\n")
  end

  # Checks that the equipment_object is of type equipment_model
  def matched_object_and_model
    return unless equipment_object
    return unless equipment_model
    return unless equipment_object.equipment_model != equipment_model
    errors.add(:base, equipment_object.name + ' must be of type '\
      + equipment_model.name + ".\n")
  end

  # Checks that the equipment model is available from start date to due date
  def available
    # do not run on reservations that don't matter anymore
    return if checked_in || due_date < Date.current
    return unless equipment_model
    return unless equipment_model.num_available(start_date, due_date) <= 0
    errors.add(:base, equipment_model.name + ' is not available for the '\
      "full time period requested.\n")
  end

  # Checks that reservation is not in the past
  # Does not run on checked out, checked in, overdue, or missed Reservations
  def not_in_past
    return unless due_date < Date.current || start_date < Date.current
    errors.add(:base, "Cannot create reservation in the past\n")
  end
end
