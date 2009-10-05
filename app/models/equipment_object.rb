class EquipmentObject < ActiveRecord::Base
  belongs_to :equipment_model
  has_and_belongs_to_many :reservations
  
  validates_presence_of :name
  
  attr_accessible :name, :serial, :equipment_model_id
  
  def status
    "available"
  end
end
