class Reservation < ActiveRecord::Base
  # has_many :equipment_models_reservations
  belongs_to :equipment_model
  belongs_to :equipment_object
  belongs_to :reserver, :class_name => 'User'
  belongs_to :checkout_handler, :class_name => 'User'
  belongs_to :checkin_handler, :class_name => 'User'

  validates_presence_of :reserver
  validates_presence_of :start_date
  validates_presence_of :due_date
  validate :not_empty
  #Currently this prevents checking in overdue items. We can work on a better fix.
  #validate :not_in_past
  validate :start_date_before_due_date

  named_scope :pending, {:conditions => ["checked_out IS NULL and checked_in IS NULL"], :order => 'start_date ASC'}

  named_scope :checked_out, lambda { {:conditions => ["checked_out IS NOT NULL and checked_in IS NULL and due_date >=  ?", Time.now.midnight.utc ], :order => 'start_date ASC' } }


  named_scope :overdue, lambda { {:conditions => ["checked_out IS NOT NULL and checked_in IS NULL and due_date < ?", Time.now.midnight.utc ], :order => 'start_date ASC' } }
  named_scope :active, :conditions => ["checked_in IS NULL"] #anything that's been reserved but not returned (i.e. pending, checked out, or overdue)
  named_scope :returned, :conditions => ["checked_in IS NOT NULL and checked_out IS NOT NULL"]
  #named_scope :due_for_checkout_old_version, lambda { { :conditions => ["checked_out IS NULL and checked_in IS NULL and start_date <= ? and due_date >= ?", Time.now.midnight.utc, Time.now.midnight.utc ], :order => 'start_date ASC'} }
  #named_scope :due_for_checkin_old_version, lambda { { :conditions => ["checked_out IS NOT NULL and checked_in IS NULL"], :order => 'start_date ASC'} }
    attr_accessible :reserver, :reserver_id, :checkout_handler, :checkout_handler_id, :checkin_handler, :checkin_handler_id, :start_date, :due_date, :checked_out, :checked_in, :equipment_model_id, :equipment_object_id

  def status
    #TODO: check this logic
    if checked_out.nil?
      "reserved"
    elsif checked_in.nil?
      due_date < Date.today ? "overdue" : "checked out"
    else
      "returned"
    end
  end
  # Some methods are not being implemented...
  def not_empty
    errors.add_to_base("A reservation must contain at least one item.") if self.equipment_model.nil?
  end

  def self.due_for_checkin(user)
    Reservation.find(:all, :conditions => ["checked_out IS NOT NULL and checked_in IS NULL and reserver_id = ?", user.id], :order => 'start_date ASC')
  end

  def self.due_for_checkout(user)
    Reservation.find(:all, :conditions => ["checked_out IS NULL and checked_in IS NULL and reserver_id = ? and start_date <= ?", user.id, Time.now.midnight.utc], :order => 'start_date ASC')
  end

  def self.overdue_reservations?(user)
    Reservation.find(:all, :conditions => ["checked_out IS NOT NULL and checked_in IS NULL and due_date < ?", Time.now.midnight.utc,], :order => 'start_date ASC').count >= 1
  end

  def self.active_reservations
    Reservation.find(:all, :conditions => ["checked_in IS NULL"], :order => 'start_date ASC')
  end

    def self.category_limit_reached?(reservation)
    user_current_reservations = Reservation.find(:all, :conditions => ["checked_out IS NOT NULL and checked_in IS NULL and reserver_id = ?", reservation.reserver_id])
    user_current_categories = []
    user_current_reservations.each do |r|
      user_current_categories << r.equipment_model.category.id
    end
    user_current_categories.count(reservation.equipment_model.category.id) >= (reservation.equipment_model.category.max_per_user)
  end

  def self.equipment_model_limit_reached?(reservation)
    user_current_reservations = Reservation.find(:all, :conditions => ["checked_out IS NOT NULL and checked_in IS NULL and reserver_id = ?", reservation.reserver_id])
    user_current_models = []
    user_current_reservations.each do |r|
      user_current_models << r.equipment_model_id
    end
    if !EquipmentModel.find(reservation.equipment_model_id).max_per_user.nil?
      user_current_models.count(reservation.equipment_model_id) >= reservation.equipment_model.max_per_user
    else
      false
    end
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

  def not_in_past
    errors.add_to_base("A reservation cannot be made in the past!") if self.due_date < Time.now.midnight
  end

  def start_date_before_due_date
    errors.add_to_base("A reservation's due date must come after its start date.") if self.due_date < self.start_date
  end

  def late_fee
    self.equipment_model.late_fee.to_f
  end

  def equipment_list
    raw_text = ""
 #   Reservation.find(:all, :conditions => ["reserver_id = ?", @user.id]).each do |reservation|
  #    if reservation.equipment_model
   #     raw_text += "1 x #{reservation.equipment_model.name}\r\n"
    #  else
     #   raw_text += "1 x *equipment deleted*\r\n"
     # end
    #end
    raw_text
  end

  # def equipment_object_id=(ids)
  #   ids.each do |id|
  #     equipment_objects << EquipmentObject.find(id)
  #   end
  # end
private

  def redirect_to_check_out(msg = nil)
    flash[:notice] = msg if msg
    redirect_to :action => 'check_out'
  end



end

