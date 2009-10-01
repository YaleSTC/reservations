class EquipmentObject < ActiveRecord::Base
  belongs_to :equipment_model
  
  attr_accessible :name, :serial, :equipment_model
end
