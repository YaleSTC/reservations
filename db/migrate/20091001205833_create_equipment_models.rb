class CreateEquipmentModels < ActiveRecord::Migration
  def self.up
    create_table :equipment_models do |t|
      t.string :name
      t.text :description
      t.decimal :late_fee
      t.decimal :replacement_fee
      t.integer :max_per_user
      t.references :category
      t.timestamps
    end
  end
  
  def self.down
    drop_table :equipment_models
  end
end
