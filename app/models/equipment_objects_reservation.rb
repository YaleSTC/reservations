class EquipmentObjectsReservation < ActiveRecord::Base
  belongs_to :reservation
  belongs_to :equipment_object
end
