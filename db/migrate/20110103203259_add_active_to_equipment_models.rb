class AddActiveToEquipmentModels < ActiveRecord::Migration
  def self.up
    add_column :equipment_models, :active, :boolean, :default => true
  end

  def self.down
    remove_column :equipment_models, :active
  end
end