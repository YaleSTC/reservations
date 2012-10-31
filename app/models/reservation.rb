class Reservation < ActiveRecord::Base
  include ReservationValidations

  belongs_to :equipment_object
  belongs_to :checkout_handler, :class_name => 'User'
  belongs_to :checkin_handler, :class_name => 'User'

  validates :reserver,
            :start_date,
            :due_date,
            :equipment_model,
            :presence => true

  # If there is no equipment model, don't run the validations that would break
  with_options :if => :not_empty? do |r|
    r.validate :start_date_before_due_date?, :matched_object_and_model?, :not_in_past?,
              :duration_allowed?, :available?, :start_date_is_not_blackout?,
              :due_date_is_not_blackout?, :quantity_eq_model_allowed?, :quantity_cat_allowed?
    r.validate :not_in_past?, :not_renewable?, :no_overdue_reservations?, :on => :create
  end

  scope :recent, order('start_date, due_date, reserver_id')
  scope :user_sort, order('reserver_id')
  scope :reserved, lambda { where("checked_out IS NULL and checked_in IS NULL and due_date >= ?", Time.now.midnight.utc).recent}
  scope :checked_out, lambda { where("checked_out IS NOT NULL and checked_in IS NULL and due_date >=  ?", Time.now.midnight.utc).recent }
  scope :checked_out_today, lambda { where("checked_out >= ? and checked_in IS NULL", Time.now.midnight.utc).recent }
  scope :checked_out_previous, lambda { where("checked_out < ? and checked_in IS NULL and due_date <= ?", Time.now.midnight.utc, Date.tomorrow.midnight.utc).recent }
  scope :overdue, lambda { where("checked_out IS NOT NULL and checked_in IS NULL and due_date < ?", Time.now.midnight.utc ).recent }
  scope :returned, where("checked_in IS NOT NULL and checked_out IS NOT NULL")
  scope :returned_on_time, where("checked_in IS NOT NULL and checked_out IS NOT NULL and due_date >= checked_in").recent
  scope :returned_overdue, where("checked_in IS NOT NULL and checked_out IS NOT NULL and due_date < checked_in").recent
  scope :missed, lambda {where("checked_out IS NULL and checked_in IS NULL and due_date < ?", Time.now.midnight.utc).recent}
  scope :upcoming, lambda {where("checked_out IS NULL and checked_in IS NULL and start_date = ? and due_date > ?", Time.now.midnight.utc, Time.now.midnight.utc).user_sort }
  scope :reserver_is_in, lambda {|user_id_arr| where(:reserver_id => user_id_arr)}
  scope :starts_on_days, lambda {|start_date, end_date|  where(:start_date => start_date..end_date)}
  scope :active, where("checked_in IS NULL") #anything that's been reserved but not returned (i.e. pending, checked out, or overdue)
  scope :notes_unsent, :conditions => {:notes_unsent => true}

  #TODO: Why the duplication in checkout_handler and checkout_handler_id (etc)?
  attr_accessible :checkout_handler, :checkout_handler_id,
                  :checkin_handler, :checkin_handler_id,
                  :checked_out, :checked_in, :equipment_object,
                  :equipment_object_id, :notes, :notes_unsent, :times_renewed

  def reserver
    User.include_deleted.find(self.reserver_id)
  end

  def status
    if checked_out.nil?
      if checked_in.nil?
        due_date >= Date.today ? "reserved" : "missed"
      else
        "?"
      end
    elsif checked_in.nil?
      due_date < Date.today ? "overdue" : "checked out"
    else
      due_date < checked_in.to_date ? "returned overdue" : "returned on time"
    end

  end

  ## Set validation
  # Checks all validations for all saved reservations and the reservations in
  # the array of reservations passed in (use with cart.cart_reservations)
  # Returns an array of error messages or [] if reservations are all valid
  def self.validate_set(user, res_array = [])
    all_res_array = res_array + user.reservations
    errors = []
    all_res_array.each do |res|
      errors << user.name + " has overdue reservations that prevent new ones from being created" unless res.no_overdue_reservations?
      errors << "Reservations cannot be made in the past" unless res.not_in_past? if self.class == CartReservation
      errors << "Reservations start dates must be before due dates" unless res.start_date_before_due_date?
      errors << "Reservations must have an associated equipment model" unless res.not_empty?
      errors << res.equipment_object.name + " must be of type " + res.equipment_model.name unless res.matched_object_and_model?
      errors << res.equipment_model.name + " should be renewed instead of re-checked out" unless res.not_renewable? if self.class == CartReservation
      errors << "Duration of " + res.equipment_model.name + " reservation must be less than " + res.equipment_model.category.maximum_checkout_length.to_s unless res.duration_allowed?
      errors << res.equipment_model.name + " is not available for the full time period requested" unless res.available?(res_array)
      errors << "A reservation cannot start on " + res.start_date.strftime('%m/%d') + " because equipment cannot be picked up on that date" unless res.start_date_is_not_blackout?
      errors << "A reservation cannot end on " + res.due_date.strftime('%m/%d') + " because equipment cannot be returned on that date" unless res.due_date_is_not_blackout?
      errors << "Quantity of " + res.equipment_model.name.pluralize + " must not exceed " + res.equipment_model.maximum_per_user.to_s unless res.quantity_eq_model_allowed?(res_array)
      errors << "Quantity of " + res.equipment_model.category.name.pluralize + " must not exceed " + res.equipment_model.category.maximum_per_user.to_s unless res.quantity_cat_allowed?(res_array)
	end
  errors.uniq
  end


  def self.due_for_checkin(user)
    Reservation.where("checked_out IS NOT NULL and checked_in IS NULL and reserver_id = ?", user.id).order('due_date ASC') # put most-due ones first
  end

  def self.due_for_checkout(user)
    Reservation.where("checked_out IS NULL and checked_in IS NULL and start_date <= ? and due_date >= ? and reserver_id =?", Time.now.midnight.utc, Time.now.midnight.utc, user.id).order('start_date ASC')
  end

  def self.overdue_reservations?(user)
    Reservation.where("checked_out IS NOT NULL and checked_in IS NULL and reserver_id = ? and due_date < ?", user.id, Time.now.midnight.utc,).order('start_date ASC').count >= 1 #FIXME: does this need the order?
  end

  def checkout_object_uniqueness(reservations)
    object_ids_taken = []
    reservations.each do |r|
      if !object_ids_taken.include?(r.equipment_object_id) # check to see if we've already taken that one
        object_ids_taken << r.equipment_object_id
      else
        return false # return false if not unique
      end
    end
    return true # return true if unique
  end


  def self.active_user_reservations(user)
    prelim = Reservation.where("checked_in IS NULL and reserver_id = ?", user.id).order('start_date ASC')
    final = [] # initialize
    prelim.collect do |r|
      if r.status != "missed" # missed reservations are not actually active
        final << r
      end
    end
    final
  end

  def self.checked_out_today_user_reservations(user)
    Reservation.where("checked_out >= ? and checked_in IS NULL and reserver_id = ?", Time.now.midnight.utc, user.id)
  end

  def self.checked_out_previous_user_reservations(user)
    Reservation.where("checked_out < ? and checked_in IS NULL and reserver_id = ? and due_date >= ?", Time.now.midnight.utc, user.id, Time.now.midnight.utc)
  end

  def self.reserved_user_reservations(user)
    Reservation.where("checked_out IS NULL and checked_in IS NULL and due_date >= ? and reserver_id = ?", Time.now.midnight.utc, user.id)
  end

  def self.overdue_user_reservations(user)
    Reservation.where("checked_out IS NOT NULL and checked_in IS NULL and due_date < ? and reserver_id = ?", Time.now.midnight.utc, user.id )
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

  def fake_reserver_id # this is necessary for autocomplete! delete me not!
  end

  def equipment_list  # delete?
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
    renewal_length = self.equipment_model.maximum_renewal_length || 0 # the 'or 0' is to ensure renewal_length never == NIL; effectively
    while (renewal_length > 0) and (available_period == NIL)
      # the available? method cannot accept dates with time zones, and due_date has a time zone
      possible_start = (self.due_date + 1.day).to_date
      possible_due = (self.due_date+(renewal_length.days)).to_date
      if (self.equipment_model.num_available(possible_start, possible_due) > 0)
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
    # is undefined; that's also why we can't set variables to these function values before
    # the if statements
    if self.times_renewed == NIL
      self.times_renewed = 0
    end

    # you can't renew a checked in reservation
    if self.checked_in
      return false
    end

    if self.equipment_model.maximum_renewal_times == "unrestricted"
      if self.equipment_model.maximum_renewal_days_before_due == "unrestricted"
        # if they're both NIL
        return true
      else
        # due_date has a time zone, eradicate with to_date; use to_i to change to integer;
        # are we within the date range for which the button should appear?
        return ((self.due_date.to_date - Date.today).to_i < self.equipment_model.maximum_renewal_days_before_due)
      end
    elsif (self.equipment_model.maximum_renewal_days_before_due == "unrestricted")
      return (self.times_renewed < self.equipment_model.maximum_renewal_times)
    else
      # if neither is NIL, check both
      return (((self.due_date.to_date - Date.today).to_i < self.equipment_model.maximum_renewal_days_before_due) and (self.times_renewed < self.equipment_model.maximum_renewal_times))
    end
  end
end
