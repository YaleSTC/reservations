class RenameEquipmentObjects < ActiveRecord::Migration
  def change
  	rename_table :equipment_objects, :equipment_items
  	rename_column :reservations, :equipment_object_id, :equipment_item_id
  	rename_column :equipment_models, :equipment_objects_count, :equipment_items_count
  end
end
