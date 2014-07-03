class Reservation < ActiveRecord::Base
  include ReservationsBase
  include ReservationValidations

  has_paper_trail

  belongs_to :equipment_object
  belongs_to :checkout_handler, class_name: 'User'
  belongs_to :checkin_handler, class_name: 'User'

  validates :equipment_model, presence: true

  # If there is no equipment model, don't run the validations that would break
  with_options if: :not_empty? do |r|
    r.validate  :start_date_before_due_date?, :matched_object_and_model?,
                :available?
  end

  # These can't be nested with the above block because with_options clobbers
  # nested options that are the same (i.e., :if and :if)
  with_options if: Proc.new {|r| r.not_empty? && !r.bypass_validations} do |r|
    r.with_options on: :create do |r|
      r.validate  :not_in_past?, :not_renewable?, :no_overdue_reservations?,
                  :duration_allowed?, :start_date_is_not_blackout?,
                  :due_date_is_not_blackout?, :quantity_eq_model_allowed?,
                  :quantity_cat_allowed?
    end
  end

  nilify_blanks only: [:notes]

  scope :recent, order('start_date, due_date, reserver_id')
  scope :user_sort, order('reserver_id')
  scope :reserved, lambda { where("checked_out IS NULL and checked_in IS NULL and due_date >= ? and (approval_status = ? or approval_status = ?)", Time.now.midnight.utc, 'auto', 'approved').recent}
  scope :checked_out, lambda { where("checked_out IS NOT NULL and checked_in IS NULL and due_date >=  ?", Time.now.midnight.utc).recent }
  scope :checked_out_today, lambda { where("checked_out >= ? and checked_in IS NULL", Time.now.midnight.utc).recent } # shouldn't this just check checked_out = today?
  scope :checked_out_previous, lambda { where("checked_out < ? and checked_in IS NULL and due_date <= ?", Time.now.midnight.utc, Date.tomorrow.midnight.utc).recent }
  scope :overdue, lambda { where("checked_out IS NOT NULL and checked_in IS NULL and due_date < ?", Time.now.midnight.utc ).recent }
  scope :returned, where("checked_in IS NOT NULL and checked_out IS NOT NULL")
  scope :returned_on_time, where("checked_in IS NOT NULL and checked_out IS NOT NULL and due_date >= checked_in").recent
  scope :returned_overdue, where("checked_in IS NOT NULL and checked_out IS NOT NULL and due_date < checked_in").recent
  scope :not_returned, where("checked_in IS NULL and (approval_status = ? or approval_status = ?)", 'auto', 'approved').recent # called in the equipment_model model
  scope :missed, lambda {where("checked_out IS NULL and checked_in IS NULL and due_date < ? and (approval_status = ? OR approval_status = ?)", Time.now.midnight.utc, 'auto', 'approved').recent}
  scope :upcoming, lambda {where("checked_out IS NULL and checked_in IS NULL and start_date = ? and due_date > ? and (approval_status = ? or approval_status = ?)", Time.now.midnight.utc, Time.now.midnight.utc, 'auto', 'approved').user_sort }
  scope :reserver_is_in, lambda {|user_id| where("reserver_id = ? and (approval_status = ? or approval_status = ?)", user_id, 'auto', 'approved')} # does not include non-approved requests
  scope :starts_on_days, lambda {|start_date, end_date|  where(start_date: start_date..end_date)}
  scope :reserved_on_date, lambda {|date|  where("start_date <= ? and due_date >= ? and (approval_status = ? or approval_status = ?)", date.to_time.utc, date.to_time.utc, 'auto', 'approved')}
  scope :for_eq_model, lambda { |eq_model| where(equipment_model_id: eq_model.id) } # by default includes all reservations ever. limit e.g. checked_out via other scopes
  scope :active, where("checked_in IS NULL and (approval_status = ? OR approval_status = ?)", 'auto', 'approved') # anything that's been reserved but not returned (i.e. pending, checked out, or overdue)
  scope :active_or_requested, lambda {where("checked_in IS NULL and approval_status != ?", 'denied')}
  scope :notes_unsent, where(notes_unsent: true)
  scope :requested, lambda {where("start_date >= ? and approval_status = ?", Time.now.midnight.utc, 'requested')}
  scope :approved_requests, lambda {where("approval_status = ?", 'approved')}
  scope :denied_requests, lambda {where("approval_status = ?", 'denied')}
  scope :missed_requests, lambda {where("approval_status = ? and start_date < ?", 'requested', Time.now.midnight.utc)}

  scope :for_reserver, lambda { |reserver| where(reserver_id: reserver) }

  #TODO: Why the duplication in checkout_handler and checkout_handler_id (etc)?
  attr_accessible :checkout_handler, :checkout_handler_id,
                  :checkin_handler, :checkin_handler_id, :approval_status,
                  :checked_out, :checked_in, :equipment_object,
                  :equipment_object_id, :notes, :notes_unsent, :times_renewed

  attr_accessor :bypass_validations

  def reserver
    User.find(self.reserver_id)
  rescue
    #if user's been deleted, return a dummy user
    User.new( first_name: "Deleted",
              last_name: "User",
              login: "deleted",
              email: "deleted.user@invalid.address",
              nickname: "",
              phone: "555-555-5555",
              affiliation: "Deleted")
  end

  def status
    if checked_out.nil?
      if approval_status == 'auto' or approval_status == 'approved'
        due_date >= Date.today ? "reserved" : "missed"
      elsif approval_status
        approval_status
      else
        "?" # ... is this just in case an admin does something absurd in the database?
      end
    elsif checked_in.nil?
      due_date < Date.today ? "overdue" : "checked out"
    else
      due_date < checked_in.to_date ? "returned overdue" : "returned on time"
    end
  end

  ## Set validation
  # Checks all validations for
  # the array of reservations passed in (use with cart.cart_reservations)
  # Returns an array of error messages or [] if reservations are all valid
  def self.validate_set(user, res_array = [])
    errors = []
    #User reservation validations
    errors << user.name + " has overdue reservations that prevent new ones from being created. " unless user.reservations.overdue.empty?

    res_array.each do |res|
      errors << "Reservation cannot be made in the past. " unless res.not_in_past? if self.class = CartReservation
      errors << "Reservation start date must be before due date. " unless res.start_date_before_due_date?
      errors << "Reservation must be for a piece of equipment. " unless res.not_empty?
      errors << "#{res.equipment_object.name} must be of type #{res.equipment_model.name}. " unless res.matched_object_and_model?
      errors << "#{res.equipment_model.name} should be renewed instead of re-checked out. " unless res.not_renewable? if self.class = CartReservation
      errors << "#{res.equipment_model.name} cannot be reserved for more than #{res.equipment_model.category.maximum_checkout_length.to_s} days at a time. " unless res.duration_allowed?
      errors << "#{res.equipment_model.name} is not available for the full time period requested. " unless res.available?(res_array)
      errors << "A reservation cannot start on #{res.start_date.strftime('%m/%d')} because equipment cannot be picked up on that date. " unless res.start_date_is_not_blackout?
      errors << "A reservation cannot end on #{res.due_date.strftime('%m/%d')} because equipment cannot be returned on that date. " unless res.due_date_is_not_blackout?
      errors << "Cannot reserve more than #{res.equipment_model.maximum_per_user.to_s} #{res.equipment_model.name.pluralize}. " unless res.quantity_eq_model_allowed? res_array
      errors << "Cannot reserve more than #{res.equipment_model.category.maximum_per_user.to_s} #{res.equipment_model.category.name.pluralize}. " unless res.quantity_cat_allowed? res_array
    end
    errors.uniq
  end


  def checkout_object_uniqueness(reservations)
    object_ids_taken = []
    reservations.each do |r|
      return false if object_ids_taken.include?(r.equipment_object_id)
      object_ids_taken << r.equipment_object_id
    end
    return true # return true if unique
  end

  def late_fee
    self.equipment_model.late_fee.to_f
  end

  def fake_reserver_id # this is necessary for autocomplete! delete me not!
  end

  def max_renewal_length_available
    # determine the max renewal length for a given reservation
    eq_model = self.equipment_model
    for renewal_length in 1...eq_model.maximum_renewal_length do
      break if eq_model.available_count(self.due_date + renewal_length.day) == 0
    end
    renewal_length - 1
  end

  def is_eligible_for_renew?
    # determines if a reservation is eligible for renewal, based on how many days before the due
    # date it is and the max number of times one is allowed to renew
    #
    self.times_renewed ||= 0

    # you can't renew a checked in reservation, or one without an equipment model
    return false if self.checked_in || self.equipment_object.nil?

    max_renewal_times = self.equipment_model.maximum_renewal_times
    max_renewal_times = Float::INFINITY if max_renewal_times == 'unrestricted'

    max_renewal_days = self.equipment_model.maximum_renewal_days_before_due
    max_renewal_days = Float::INFINITY if max_renewal_days == 'unrestricted'

    return ((self.due_date.to_date - Date.today).to_i < max_renewal_days ) &&
      (self.times_renewed < max_renewal_times)
  end
end
