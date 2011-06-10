class EquipmentObject < ActiveRecord::Base
  belongs_to :equipment_model
  has_many :reservations
  
  validates_presence_of :name
  
  attr_accessible :name, :serial, :equipment_model_id
  
  def status
    if !(@current_reservation = self.reservations).empty?
      "checked out to #{@current_reservation[0].reserver.name} through #{@current_reservation[0].due_date.strftime("%b %d")}"
    else
      "available"
    end
  end
  
  def available?
    status == "available"
  end
end
