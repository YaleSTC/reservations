  belongs_to :equipment_model
  belongs_to :reserver, :class_name => 'User'

  validates :reserver,
            :start_date,
            :due_date,
            :presence => true

  attr_accessible :reserver, :reserver_id, :start_date, :due_date,
                  :equipment_model_id

  ## Validations ##

  ## For individual reservations only
  # Checks if the user has any overdue reservations
  def no_overdue_reservations?
    if reserver.reservations.overdue_reservations?(reserver)
      errors.add(:base, "availablity problem with " + equipment_model.name)
      return false
    end
    return true
  end

  # Checks that reservation start date is before end dates
  def start_date_before_due_date?
    if due_date < start_date
      errors.add(:base, "Reservation start date must be before due date")
      return false
    end
    return true
  end

  # Checks that reservation is not in the past
  #TODO: this prevents working with non-new reservations -- fix pls
  def not_in_past?
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
    unless equipment_model.nil? || equipment_object.nil?
      if equipment_object.equipment_model != equipment_model
        errors.add(:base, equipment_object.name + " is not of type " + equipment_model.name)
        return false
      end
    end
    return true
  end

  # Checks that the reservation is not renewable
  def not_renewable?
    current_reservations = reserver.reservations
    current_reservations.each do |res|
      if res.equipment_model == self.equipment_model && res.due_date.to_date == self.start_date && res.is_eligible_for_renew?
        errors.add(:base, res.equipment_model.name + " should be renewed instead of re-checked out")
        return false
      end
    end
    return true
  end

  # Checks that the reservation is not longer than the max checkout length
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
  def available?(reservations = [])
    reservations << self if reservations.empty?
    eq_objects_needed = count(reservations)
    if equipment_model.available?(start_date, due_date) < eq_objects_needed
      errors.add(:base, "availablity problem with " + equipment_model.name)
      return false
    end
    return true
  end

  # Checks that the number of equipment models that a user has reservered and in
  # the array of reservations is less than the equipment model maximum
  def quantity_eq_model_allowed?(reservations = [])
    max = equipment_model.max_per_user
    return true if max == "unrestricted"
    reservations << self if reservations.empty?
    reservations.concat(reserver.reservations)
    num_reservations = count(reservations)
    if num_reservations > max
      errors.add(:base, "quantity equipment model problem with " + equipment_model.name)
      return false
    end
    return true
  end

  # Checks that the number of items that the user has reservered and in the
  # array of reservations does not exceed the maximum in the category of the
  # reservation it is called on
  def quantity_cat_allowed?(reservations = [])
    max = equipment_model.category.max_per_user
    return true if max == "unrestricted"
    reservations << self if reservations.empty?
    reservations.concat(reserver.reservations)
    cat_count = 0
    reservations.each { |res| cat_count += 1 if res.equipment_model.category == self.equipment_model.category }
    if cat_count > max
      errors.add(:base, "quantity category problem with " + equipment_model.category.name)
      return false
    end
    return true
  end

  ## Set validation
  # Checks all validations for all saved reservations and the reservations in
  # the array of reservations passed in (intended for use with cart.items)
  # Returns an array of error messages or [] if reservations are all valid
  def self.validate_set(user, reservations = [])
    reservations.concat(user.reservations)
    errors = []
    reservations.each do |res|
      errors << "User has overdue reservations that prevent new ones from being created" if !res.no_overdue_reservations?
      errors << "Reservations cannot be made in the past" if !res.not_in_past?
      errors << "Reservations must have start dates before due dates" if !res.start_date_before_due_date?
      errors << "Reservations must have an associated equipment model" if !res.not_empty?
      errors << res.equipment_object.name + " should be of type " + res.equipment_model.name if !res.matched_object_and_model?
      errors << res.equipment_model.name + " should be renewed instead of re-checked out" if !res.not_renewable?
      errors << "duration problem with " + res.equipment_model.name if !res.duration_allowed?
      errors << "availablity problem with " + res.equipment_model.name if !res.available?(reservations)
      errors << "quantity equipment model problem with " + res.equipment_model.name if !res.quantity_eq_model_allowed?(reservations)
      errors << "quantity category problem with " + res.equipment_model.category.name if !res.quantity_cat_allowed?(reservations)
    end
    errors.uniq
  end


  ## Validation helpers, etc ##

  # Returns the number of reservations in the array of reservations it is passed
  # that have the same equipment model as the reservation count is called on
  # Assumes that self is in the array of reservations/does not include self
  # Assumes that all reservations have same start and end date as self
  def count(reservations)
    count = 0
    reservations.each { |res| count += 1 if res.equipment_model == self.equipment_model }
    count
  end

  def self.overdue_reservations?(user)
    Reservation.where("checked_out IS NOT NULL and checked_in IS NULL and reserver_id = ? and due_date < ?", user.id, Time.now.midnight.utc,).order('start_date ASC').count >= 1 #FIXME: does this need the order?
  end

  def is_eligible_for_renew?
    # determines if a reservation is eligible for renewal, based on how many days before the due
    # date it is and the max number of times one is allowed to renew
    #
    # we need to test if any of the variables are set to NIL, because in that case comparision
    # is undefined; that's also why we can't set variables to these values before the if statements
    if self.times_renewed == NIL
      self.times_renewed = 0
    end
    if self.equipment_model.maximum_renewal_times == "unrestricted"
      if self.equipment_model.maximum_renewal_days_before_due == "unrestricted"
        # if they're both NIL
        true
      else
        # due_date has a time zone, eradicate with to_date; use to_i to change to integer;
        # are we within the date range for which the button should appear?
        ((self.due_date.to_date - Date.today).to_i < self.equipment_model.maximum_renewal_days_before_due)
      end
    elsif (self.equipment_model.maximum_renewal_days_before_due == "unrestricted")
      # implicitly, max_renewal_times != NIL, so we can check it
      self.times_renewed < self.equipment_model.maximum_renewal_times
    else
      # if neither is NIL, check both
      ((self.due_date.to_date - Date.today).to_i < self.equipment_model.maximum_renewal_days_before_due) and (self.times_renewed < self.equipment_model.maximum_renewal_times)
    end
  end
end
