class Reservation < ActiveRecord::Base
  # has_many :equipment_models_reservations
  belongs_to :equipment_model
  belongs_to :equipment_object
  belongs_to :reserver, :class_name => 'User'
  belongs_to :checkout_handler, :class_name => 'User'
  belongs_to :checkin_handler, :class_name => 'User'

  validates :reserver,
            :start_date,
            :due_date,
            :presence => true

  validate :not_empty?, :not_in_past?, :start_date_before_due_date?,
           :no_overdue_reservations?, :duration_allowed?, #:available?,
           :quantity_eq_model_allowed?, :quantity_cat_allowed?


  scope :recent, order('start_date, due_date, reserver_id')

  scope :reserved, lambda { where("checked_out IS NULL and checked_in IS NULL and due_date >= ?", Time.now.midnight.utc).recent}
  scope :checked_out, lambda { where("checked_out IS NOT NULL and checked_in IS NULL and due_date >=  ?", Time.now.midnight.utc).recent }
  scope :overdue, lambda { where("checked_out IS NOT NULL and checked_in IS NULL and due_date < ?", Time.now.midnight.utc ).recent }
  scope :returned, where("checked_in IS NOT NULL and checked_out IS NOT NULL")
  scope :missed, lambda {where("checked_out IS NULL and checked_in IS NULL and due_date < ?", Time.now.midnight.utc).recent}
  scope :upcoming, lambda {where("checked_out IS NULL and checked_in IS NULL and start_date = ? and due_date > ?", Time.now.midnight.utc, Time.now.midnight.utc).recent }

  scope :active, where("checked_in IS NULL") #anything that's been reserved but not returned (i.e. pending, checked out, or overdue)
  scope :notes_unsent, :conditions => {:notes_unsent => true}

  attr_accessible :reserver, :reserver_id, :checkout_handler, :checkout_handler_id,
                  :checkin_handler, :checkin_handler_id, :start_date, :due_date,
                  :checked_out, :checked_in, :equipment_object, :equipment_model_id,
                  :equipment_object_id, :notes, :notes_unsent, :times_renewed

  def status
    if checked_out.nil? && due_date >= Date.today
      "reserved"
    elsif checked_out.nil? && due_date < Date.today
      "missed"
    elsif checked_in.nil?
      due_date < Date.today ? "overdue" : "checked out"
    else
      "returned"
    end
  end

  ## Validations ##

  ## For individual reservations only
  # Checks that the reservation has an equipment model
  def not_empty?
    return false if equipment_model.nil?
    return true
  end

  # Checks that reservation is not in the past
  def not_in_past?
    return false if (start_date < Date.today) || (due_date < Date.today)
    return true
  end

  # Checks that reservation start date is before end dates
  def start_date_before_due_date?
    return false if due_date < start_date
    return true
  end

  # Checks that the reservation is not longer than the max checkout length
  def duration_allowed?
    duration = due_date - start_date + 1
    cat_duration = equipment_model.category.max_checkout_length
    return false if duration > cat_duration
    return true
  end

  # Checks if the user has any overdue reservations
  def no_overdue_reservations?
    return false if reserver.reservations.overdue_reservations?(reserver)
    return true
  end

  ## For single or multiple reservations
  # Checks that the equipment model is available from start date to due date
  def available?(reservations = [])
    reservations << self if reservations.empty?
    eq_objects_needed = count(reservations)
    return false if equipment_model.available?(start_date..due_date) < eq_objects_needed
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
    return false if num_reservations > max
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
    return false if cat_count > max
    return true
  end

  ## Set validation
  # Checks all validations for all saved reservations and the reservations in
  # the array of reservations passed in (intended for use with cart.items)
  # Returns an array of error messages or [] if reservations are all valid
  def self.validate_set(reserver, reservations = [])
    reservations.concat(reserver.reservations)
    errors = []
    reservations.each do |res|
      errors << "User has overdue reservations that prevent new ones from being created" if !res.no_overdue_reservations?
      errors << "Reservations cannot be made in the past" if !res.not_in_past?
      errors << "Reservations must have start dates before due dates" if !res.start_date_before_due_date?
      errors << "Reservations must have an associated equipment model" if !res.not_empty?
      errors << "duration problem with " + res.equipment_model.name if !res.duration_allowed?
#      errors << "availablity problem with " + res.equipment_model.name if !res.available?(reservations)
      errors << "quantity equipment model problem with " + res.equipment_model.name if !res.quantity_eq_model_allowed?(reservations)
      errors << "quantity category problem with " + res.equipment_model.category.name if !res.quantity_cat_allowed?(reservations)
    end
    #TODO: delete duplicate error messages
    errors
  end

  ## Validation helpers ##

  # Returns the number of reservations in the array of reservations it is passed
  # that have the same equipment model as the reservation count is called on
  # Assumes that self is in the array of reservations/does not include self
  # Assumes that all reservations have same start and end date as self
  def count(reservations)
    count = 0
    reservations.each { |res| count += 1 if res.equipment_model_id == self.equipment_model_id }
    count
  end

  def self.due_for_checkin(user)
    Reservation.where("checked_out IS NOT NULL and checked_in IS NULL and reserver_id = ?", user.id).order('start_date ASC')
  end

  def self.due_for_checkout(user)
    Reservation.where("checked_out IS NULL and checked_in IS NULL and start_date <= ? and due_date >= ? and reserver_id =?", Time.now.midnight.utc, Time.now.midnight.utc, user.id).order('start_date ASC')
  end

  def self.overdue_reservations?(user)
    Reservation.where("checked_out IS NOT NULL and checked_in IS NULL and reserver_id = ? and due_date < ?", user.id, Time.now.midnight.utc,).order('start_date ASC').count >= 1 #FIXME: does this need the order?
  end

  def check_out_permissions(reservations, procedures_count)
    error_messages = ""
    if reservations.nil?
      error_messages += "No reservations selected!"
    else
      current_patron_id = reservations.first.reserver.id
      user_current_reservations = Reservation.where("checked_out IS NOT NULL and checked_in IS NULL and reserver_id = ?", current_patron_id)
      user_current_categories = []
      user_current_models = []
      user_current_reservations.each do |r|
        user_current_categories << r.equipment_model.category.id
        user_current_models << r.equipment_model_id
      end

      #Check if all check out procedures have been met
      Hash[reservations.zip(procedures_count)].each do |reservation, procedure_count|
        if Reservation.check_out_procedures_exist?(reservation)
          if reservation.equipment_model.checkout_procedures.count != procedure_count #For now, this check can only be passed if ALL procedures are checked off
            error_messages += "Checkout Procedures for #{reservation.equipment_model.name} not Completed."
          end
        end
      end

      reservations.each do |reservation|

        #Check if category limit has been reached
        if !reservation.equipment_model.category.max_per_user.nil? && user_current_categories.count(reservation.equipment_model.category.id) >= (reservation.equipment_model.category.max_per_user)
          error_messages += "Category limit for #{reservation.equipment_model.category.name} has been reached."
        end

        #Check if equipment model limit has been reached
        if !EquipmentModel.find(reservation.equipment_model_id).max_per_user.nil?
          if user_current_models.count(reservation.equipment_model_id) >= reservation.equipment_model.max_per_user
            error_messages += "Equipment Model limit for #{reservation.equipment_model.name} has been reached."
          end
        end


      end
    end
    error_messages
  end

  def check_in_permissions(reservations, procedures_count)
    error_messages = ""
    Hash[reservations.zip(procedures_count)].each do |reservation, procedure_count|
      if Reservation.check_in_procedures_exist?(reservation)
        if reservation.equipment_model.checkin_procedures.count != procedure_count #For now, this check can only be passed if ALL procedures are checked off
          error_messages += "Checkin Procedures for #{reservation.equipment_model.name} not completed."
        end
      end
    end
    error_messages
  end

  def self.active_user_reservations(user)
    Reservation.where("checked_in IS NULL and reserver_id = ?", user.id).order('start_date ASC')
  end

  def self.check_out_procedures_exist?(reservation)
    !reservation.equipment_model.checkout_procedures.nil?
  end

  def self.check_in_procedures_exist?(reservation)
    !reservation.equipment_model.checkin_procedures.nil?
  end

  def self.empty_reservation?(reservation)
    reservation.equipment_object.nil?
  end

  def late_fee
    self.equipment_model.late_fee.to_f
  end

  def equipment_list
    raw_text = ""
    #Reservation.where("reserver_id = ?", @user.id).each do |reservation|
    #if reservation.equipment_model
    #  raw_text += "1 x #{reservation.equipment_model.name}\r\n"
    #else
    #  raw_text += "1 x *equipment deleted*\r\n"
    #end
    raw_text
  end

  # def equipment_object_id=(ids)
  #   ids.each do |id|
  #     equipment_objects << EquipmentObject.find(id)
  #   end
  # end

  def fake_reserver_id # Necessary for auto-complete feature
  end

  def max_renewal_length_available
  # available_period is what is returned by the function
  # initialize to NIL because once it's set we escape the while loop below
    available_period = NIL
    renewal_length = self.equipment_model.maximum_renewal_length
    while (renewal_length > 0) and (available_period == NIL)
      # the available? method cannot accept dates with time zones, and due_date has a time zone
      possible_dates_range = (self.due_date + 1.day).to_date..(self.due_date+(renewal_length.days)).to_date
      if (self.equipment_model.available?(possible_dates_range) > 0)
        # if it's available for the period, set available_period and escape loop
        available_period = renewal_length
      else
        # otherwise shorten reservation renewal period by one day and try again
        renewal_length -= 1
      end
    end
    # need this case to account for when renewal_length == 0 and it escapes the while loop
    # before available_period is set
    return available_period = renewal_length
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
