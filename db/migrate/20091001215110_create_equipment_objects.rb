class CreateEquipmentObjects < ActiveRecord::Migration
  def self.up
    create_table :equipment_objects do |t|
      t.string :name
      t.string :serial
      t.boolean :active, :default => true
      t.references :equipment_model
      t.timestamps
    end
  end
  
  def self.down
    drop_table :equipment_objects
  end
end
