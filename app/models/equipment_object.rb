class EquipmentObject < ActiveRecord::Base
  belongs_to :equipment_model
  has_and_belongs_to_many :reservations
  
  attr_accessible :name, :serial, :equipment_model_id
  
  def status
    "Available"
  end
end
