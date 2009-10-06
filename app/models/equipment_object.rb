class EquipmentObject < ActiveRecord::Base
  belongs_to :equipment_model
  has_and_belongs_to_many :reservations
  
  validates_presence_of :name
  
  attr_accessible :name, :serial, :equipment_model_id
  
  def status
    if !(@current_reservation = self.reservations).empty?
      "checked out to "+@current_reservation[0].reserver.name
    else
      "available"
    end
  end
  
  def available?
    status == "available"
  end
end
