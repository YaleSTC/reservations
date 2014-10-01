class AddNotesToEquipmentObjects < ActiveRecord::Migration
  def change
    add_column :equipment_objects, :notes, :text
  end
end
