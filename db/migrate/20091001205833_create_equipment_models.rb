class CreateEquipmentModels < ActiveRecord::Migration
  def self.up
    create_table :equipment_models do |t|
      t.string :name
      t.text :description
      t.decimal :late_fee, :precision => 10, :scale => 2
      t.decimal :replacement_fee, :precision => 10, :scale => 2
      t.integer :max_per_user
      t.boolean :active, :default => true
      t.references :category
      t.timestamps
    end
  end
  
  def self.down
    drop_table :equipment_models
  end
end
