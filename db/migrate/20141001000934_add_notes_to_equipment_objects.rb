class AddNotesToEquipmentObjects < ActiveRecord::Migration
  def change
    add_column :equipment_objects, :notes, :text, limit: 16777215, null: false
  end
end
