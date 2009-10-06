class CreateAccessoriesEquipmentModels < ActiveRecord::Migration
  def self.up
    create_table :accessories_equipment_models do |t|
      t.references :accessory
      t.references :equipment_model
      t.timestamps
    end
  end

  def self.down
    drop_table :accessories_equipment_models
  end
end