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
  
  validate :not_empty
  validate :start_date_before_due_date
  #Currently this prevents checking in overdue items. We can work on a better fix.
  #validate :not_in_past
  

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
  
  attr_accessible :reserver, :reserver_id, :checkout_handler, :checkout_handler_id, 
                  :checkin_handler, :checkin_handler_id, :start_date, :due_date, 
                  :checked_out,:checked_in, :equipment_object, :equipment_model_id, 
                  :equipment_object_id, :notes, :notes_unsent, :times_renewed

  def reserver
    User.include_deleted.find(self.reserver_id)
  end

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
  
  #should reconcile the two status functions
  def status_for_report
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

  def not_empty
    errors.add_to_base("A reservation must contain at least one item.") if self.equipment_model.nil?
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
        if !EquipmentModel.include_deleted.find(reservation.equipment_model_id).max_per_user.nil?
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

  #These two methods (not_in_past and start_date_before_due_date) don't seem to be working
  def not_in_past
    errors.add_to_base("A reservation cannot be made in the past!") if self.due_date < Time.now.midnight
  end

  def start_date_before_due_date
    errors.add_to_base("A reservation's due date must come after its start date.") if self.due_date < self.start_date
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
    # is undefined; that's also why we can't set variables to these function values before 
    # the if statements
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

