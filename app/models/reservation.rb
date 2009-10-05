class Reservation < ActiveRecord::Base
  has_many :equipment_models_reservations
  has_many :equipment_models, :through => :equipment_models_reservations
  #has_and_belongs_to_many :equipment_objects
  belongs_to :reserver, :class_name => 'User'
  belongs_to :checkout_handler, :class_name => 'User'
  belongs_to :checkin_handler, :class_name => 'User'
  
  validates_presence_of :reserver
  validates_presence_of :start_date
  validates_presence_of :due_date
  validate :not_empty
  
  attr_accessible :reserver, :reserver_id, :checkout_handler, :checkout_handler_id, :checkin_handler, :checkin_handler_id, :start_date, :due_date, :checked_out, :checked_in
  
  def status
    if checked_out.nil?
      "not checked out"
    else
      "checked out"
    end
  end
  
  def not_empty
    errors.add_to_base("A reservation must contain at least one item!") if self.equipment_models_reservations.empty?
  end
end
