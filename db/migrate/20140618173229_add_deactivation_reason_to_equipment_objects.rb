class AddDeactivationReasonToEquipmentObjects < ActiveRecord::Migration
  def change
    add_column :equipment_objects, :deactivation_reason, :string, default: nil
  end
end
