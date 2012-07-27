class Reservation < ActiveRecord::Base
  include ReservationValidations

  belongs_to :equipment_object
  belongs_to :checkout_handler, :class_name => 'User'
  belongs_to :checkin_handler, :class_name => 'User'

  validates :reserver,
            :start_date,
            :due_date,
            :presence => true

#  validate :no_overdue_reservations?, :start_date_before_due_date?, :not_empty?,
#           :matched_object_and_model?, :duration_allowed?, :available?,
#           :quantity_eq_model_allowed?, :quantity_cat_allowed?

  scope :recent, order('start_date, due_date, reserver_id')
  scope :reserved, lambda { where("checked_out IS NULL and checked_in IS NULL and due_date >= ?", Time.now.midnight.utc).recent}
  scope :checked_out, lambda { where("checked_out IS NOT NULL and checked_in IS NULL and due_date >=  ?", Time.now.midnight.utc).recent }
  scope :overdue, lambda { where("checked_out IS NOT NULL and checked_in IS NULL and due_date < ?", Time.now.midnight.utc ).recent }
  scope :returned, where("checked_in IS NOT NULL and checked_out IS NOT NULL")
  scope :missed, lambda {where("checked_out IS NULL and checked_in IS NULL and due_date < ?", Time.now.midnight.utc).recent}
  scope :upcoming, lambda {where("checked_out IS NULL and checked_in IS NULL and start_date = ? and due_date > ?", Time.now.midnight.utc, Time.now.midnight.utc).recent }
  scope :active, where("checked_in IS NULL") #anything that's been reserved but not returned (i.e. pending, checked out, or overdue)
  scope :notes_unsent, :conditions => {:notes_unsent => true}

  attr_accessible :checkout_handler, :checkout_handler_id,
                  :checkin_handler, :checkin_handler_id,
                  :checked_out, :checked_in, :equipment_object,
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

  ## Set validation
  # Checks all validations for all saved reservations and the reservations in
  # the array of reservations passed in (intended for use with cart.items)
  # Returns an array of error messages or [] if reservations are all valid
  def self.validate_set(user, res_array = [])
    all_res_array = res_array + user.reservations_array
    errors = []
    all_res_array.each do |res|
      errors << "User has overdue reservations that prevent new ones from being created" if !res.no_overdue_reservations?
      errors << "Reservations cannot be made in the past" if !res.not_in_past?
      errors << "Reservations must have start dates before due dates" if !res.start_date_before_due_date?
      errors << "Reservations must have an associated equipment model" if !res.not_empty?
      errors << res.equipment_object.name + " should be of type " + res.equipment_model.name if !res.matched_object_and_model?
      errors << res.equipment_model.name + " should be renewed instead of re-checked out" if !res.not_renewable?
      errors << "duration problem with " + res.equipment_model.name if !res.duration_allowed?
      errors << "availablity problem with " + res.equipment_model.name if !res.available?(res_array)
      errors << "quantity equipment model problem with " + res.equipment_model.name if !res.quantity_eq_model_allowed?(res_array)
      errors << "quantity category problem with " + res.equipment_model.category.name if !res.quantity_cat_allowed?(res_array)
    end
    errors.uniq
  end

  def self.overdue_reservations?(user)
    Reservation.where("checked_out IS NOT NULL and checked_in IS NULL and reserver_id = ? and due_date < ?", user.id, Time.now.midnight.utc,).order('start_date ASC').count >= 1 #FIXME: does this need the order?
  end

  def self.due_for_checkin(user)
    Reservation.where("checked_out IS NOT NULL and checked_in IS NULL and reserver_id = ?", user.id).order('start_date ASC')
  end

  def self.due_for_checkout(user)
    Reservation.where("checked_out IS NULL and checked_in IS NULL and start_date <= ? and due_date >= ? and reserver_id =?", Time.now.midnight.utc, Time.now.midnight.utc, user.id).order('start_date ASC')
  end

  def self.active_user_reservations(user)
    Reservation.where("checked_in IS NULL and reserver_id = ?", user.id).order('start_date ASC')
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

  def max_renewal_length_available
  # available_period is what is returned by the function
  # initialize to NIL because once it's set we escape the while loop below
    available_period = NIL
    renewal_length = self.equipment_model.maximum_renewal_length || 0
    while (renewal_length > 0) and (available_period == NIL)
      # the available? method cannot accept dates with time zones, and due_date has a time zone
      if (self.equipment_model.available?(self.due_date + 1.day, self.due_date + (renewal_length.days)) > 0)
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
