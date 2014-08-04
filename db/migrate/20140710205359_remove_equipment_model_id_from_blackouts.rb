class RemoveEquipmentModelIdFromBlackouts < ActiveRecord::Migration
  def up
    remove_column :blackouts, :equipment_model_id
  end

  def down
    add_column :blackouts, :equipment_model_id, :integer
  end
end
