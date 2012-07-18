class Reservation < BaseReservation
  belongs_to :equipment_model
  belongs_to :reserver, :class_name => 'User'
  belongs_to :equipment_object
  belongs_to :checkout_handler, :class_name => 'User'
  belongs_to :checkin_handler, :class_name => 'User'

  validate :no_overdue_reservations?, :start_date_before_due_date?, :not_empty?,
           :matched_object_and_model?, :duration_allowed?, :available?,
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
    renewal_length = self.equipment_model.maximum_renewal_length
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
end
