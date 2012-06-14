class EquipmentModelsAssociatedEquipmentModels < ActiveRecord::Migration
  def self.up
    create_table :equipment_models_associated_equipment_models, :id => false do |t|
      t.references :equipment_model
      t.references :associated_equipment_model
    end
  end

  def self.down
    drop_table :equipment_models_associated_equipment_models
  end
end
