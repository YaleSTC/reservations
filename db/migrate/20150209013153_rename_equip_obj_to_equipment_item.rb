class RenameEquipObjToEquipmentItem < ActiveRecord::Migration
  def change
  	rename_table :equipment_objects, :equipment_items
  end
end