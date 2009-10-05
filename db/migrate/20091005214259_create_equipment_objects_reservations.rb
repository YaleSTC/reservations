class CreateEquipmentObjectsReservations < ActiveRecord::Migration
  def self.up
    create_table :equipment_objects_reservations do |t|
      t.references :equipment_object
      t.references :reservation
      t.timestamps
    end
  end

  def self.down
    drop_table :equipment_objects_reservations
  end
end