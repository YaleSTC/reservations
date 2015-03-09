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

  # Checks that the equipment_item is of type equipment_model
  def matched_item_and_model
    return unless equipment_item
    return unless equipment_model
    return unless equipment_item.equipment_model != equipment_model
    errors.add(:base, equipment_item.name + ' must be of type '\
      + equipment_model.name + ".\n")
  end

  # Checks that the equipment model is available from start date to due date
  def available
    # do not run on reservations that don't matter anymore
    return if checked_in || due_date < Time.zone.today
    return unless equipment_model
    return unless equipment_model.num_available(start_date, due_date) <= 0
    errors.add(:base, equipment_model.name + ' is not available for the '\
      "full time period requested.\n")
  end

  # Checks that reservation is not in the past
  # Does not run on checked out, checked in, overdue, or missed Reservations
  def not_in_past
    return unless due_date < Time.zone.today || start_date < Time.zone.today
    errors.add(:base, "Cannot create reservation in the past.\n")
  end

  def check_banned
    return unless reserver.role == 'banned'
    errors.add(:base, "Reserver cannot be banned.\n")
  end
end
