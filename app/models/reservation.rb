class Reservation < ActiveRecord::Base
  has_and_belongs_to_many :equipment_models
  has_and_belongs_to_many :equipment_objects
  
  attr_accessible :reserver, :checkout_handler, :checkin_handler, :start_date, :due_date, :checked_out, :checked_in
end
