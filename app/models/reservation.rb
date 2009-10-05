class Reservation < ActiveRecord::Base
  has_many :equipment_models_reservations
  has_many :equipment_models, :through => :equipment_models_reservations
  has_and_belongs_to_many :equipment_objects
  belongs_to :reserver, :class_name => 'User'
  belongs_to :checkout_handler, :class_name => 'User'
  belongs_to :checkin_handler, :class_name => 'User'
  
  validates_presence_of :reserver
  validates_presence_of :start_date
  validates_presence_of :due_date
  validate :not_empty
  
  attr_accessible :reserver, :reserver_id, :checkout_handler, :checkout_handler_id, :checkin_handler, :checkin_handler_id, :start_date, :due_date, :checked_out, :checked_in, :equipment_object_ids
  
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
    errors.add_to_base("A reservation must contain at least one item!") if self.equipment_models_reservations.empty?
  end
  
  def late_fee
    equipment_models_reservations.map{|item| item.quantity * item.equipment_model.late_fee}.sum.to_f
  end
  
  # def equipment_object_ids=(ids)
  #   ids.each do |id|
  #     equipment_objects << EquipmentObject.find(id)
  #   end
  # end
end