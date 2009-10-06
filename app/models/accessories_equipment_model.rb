class AccessoriesEquipmentModel < ActiveRecord::Base
  belongs_to :accessory, :class_name => "EquipmentModel"
  belongs_to :equipment_model
end

