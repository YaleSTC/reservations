class EquipmentModelsReservation < ActiveRecord::Base
  belongs_to :reservation
  belongs_to :equipment_model
end
