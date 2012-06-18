class Reservation < ActiveRecord::Base
  # has_many :equipment_models_reservations
  belongs_to :equipment_model
  belongs_to :equipment_object
  belongs_to :reserver, :class_name => 'User'
  belongs_to :checkout_handler, :class_name => 'User'
  belongs_to :checkin_handler, :class_name => 'User'

  validates :reserver, :start_date, :due_date, :presence => true
  
  validate :not_empty
  validate :start_date_before_due_date
  #Currently this prevents checking in overdue items. We can work on a better fix.
  #validate :not_in_past
  

  scope :recent, order('start_date, due_date, reserver_id')
  scope :pending, where("checked_out IS NULL and checked_in IS NULL").recent
  scope :checked_out, lambda { where("checked_out IS NOT NULL and checked_in IS NULL and due_date >=  ?", Time.now.midnight.utc).recent }
  scope :overdue, lambda { where("checked_out IS NOT NULL and checked_in IS NULL and due_date < ?", Time.now.midnight.utc ).recent }
  scope :active, where("checked_in IS NULL") #anything that's been reserved but not returned (i.e. pending, checked out, or overdue)
  scope :returned, where("checked_in IS NOT NULL and checked_out IS NOT NULL")
  scope :notes_unsent, :conditions => {:notes_unsent => true}
  
  attr_accessible :reserver, :reserver_id, :checkout_handler, :checkout_handler_id, 
                  :checkin_handler, :checkin_handler_id, :start_date, :due_date, 
                  :checked_out,:checked_in, :equipment_object, :equipment_model_id, 
                  :equipment_object_id, :notes, :notes_unsent

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

  def not_empty
    errors.add_to_base("A reservation must contain at least one item.") if self.equipment_model.nil?
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
  
end

