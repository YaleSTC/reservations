class CreateEquipmentModelsReservations < ActiveRecord::Migration
  def self.up
    create_table :equipment_models_reservations do |t|
      t.references :equipment_model
      t.references :reservation
      t.references :equipment_object #for actual checkout
      t.timestamps
    end
  end

  def self.down
    drop_table :equipment_models_reservations
  end
end
