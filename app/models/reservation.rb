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
  
  attr_accessible :reserver, :reserver_id, :checkout_handler, :checkout_handler_id, :checkin_handler, :checkin_handler_id, :start_date, :due_date, :checked_out, :checked_in, :equipment_model_id, :equipment_object_id
  
  def status
    #TODO: check this logic
    if checked_out.nil?
      "reserved"
    elsif checked_in.nil?
      due_date < Date.today ? "overdue" : "checked out"
    elsif !equipment_objects.empty?
      "partially returned"
    else
      "returned"
    end
  end
  
  def not_empty
    errors.add_to_base("A reservation must contain at least one item.") if self.equipment_model.nil?
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
    self.equipment_models_reservations.each do |equipment_models_reservations|
      if equipment_models_reservations.equipment_model
        raw_text += "#{equipment_models_reservations.quantity} x #{equipment_models_reservations.equipment_model.name}\r\n"
      else
        raw_text += "#{equipment_models_reservations.quantity} x *equipment deleted*\r\n"
      end
    end
    raw_text
  end
  
  # def equipment_object_id=(ids)
  #   ids.each do |id|
  #     equipment_objects << EquipmentObject.find(id)
  #   end
  # end
end