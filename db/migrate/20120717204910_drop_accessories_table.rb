class DropAccessoriesTable < ActiveRecord::Migration
  def up
    drop_table :accessories_equipment_models
  end

  def down
    create_table :accessories_equipment_models do |t|
      t.references :accessory
      t.references :equipment_model
      t.timestamps
    end
  end
end