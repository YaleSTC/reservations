class AddDeactivatedAndDeactivationReasonToEquipmentObjects < ActiveRecord::Migration
  def change
    add_column :equipment_objects, :deactivated?, :boolean, default: false
    add_column :equipment_objects, :deactivation_reason, :string, default: nil
  end
end
