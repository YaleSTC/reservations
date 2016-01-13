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

  # Checks that the status column agrees with the actual reservation data
  # rubocop:disable all
  def check_status
    return unless self.status_changed?
    case status
    when Reservation.statuses['requested']
      if !self.flagged?(:request)
        errors.add(:base, "Request flag must be set for requested status.\n")
      end
    when Reservation.statuses['denied']
      if !self.flagged?(:request)
        errors.add(:base, "Request flag must be set for denied status.\n")
      end
    when Reservation.statuses['reserved']
      if checked_out
        errors.add(:base, "Reserved reservation must not be checked out\n")
      elsif start_date < Time.zone.today
        errors.add(:base, 'Reserved reservation must not start earlier than'\
        "today.\n")
      end
    when Reservation.statuses['checked_out']
      if !checked out
        errors.add(:base, "Checked out reservation must be checked out.\n")
      elsif checked_in
        errors.add(:base, "Checked out reservation must not be checked in.\n")
      end
    when Reservation.statuses['missed']
      if checked_out
        errors.add(:base, "Missed reservation must not be checked out.\n")
      elsif start_date >= Time.zone.today
        errors.add(:base, "Missed reservation must start before today.\n")
      end
    when Reservation.statuses['returned']
      if !checked_out
        errors.add(:base, "Returned reservation must be checked out.\n")
      elsif !checked_in
        errors.add(:base, "Returned reservation must be checked in.\n")
      end
    end
  end

  # Checks that the status is not changed when it is in a final state
  def status_final_state
    return unless status_changed?
    return unless %w(denied missed returned archived).include?(status_was)
    errors.add(:base, "Cannot change status of #{status_was}"\
    " reservation.\n")
  end
end
