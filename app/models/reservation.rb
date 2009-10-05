class Reservation < ActiveRecord::Base
  has_many :equipment_models_reservations
  has_many :equipment_models, :through => :equipment_models_reservations
  #has_and_belongs_to_many :equipment_objects
  belongs_to :reserver
  belongs_to :checkout_handler
  belongs_to :checkin_handler
  
  attr_accessible :reserver, :checkout_handler, :checkin_handler, :start_date, :due_date, :checked_out, :checked_in
  
  def status
    if checked_out.nil?
      "not checked out"
    else
      "checked out"
    end
  end
end
