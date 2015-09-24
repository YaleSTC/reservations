class AddLateFeeMaxToEquipmentModels < ActiveRecord::Migration
  def change
    add_column :equipment_models, :late_fee_max, :decimal, precision: 10,
                                                           scale: 2, default: 0
  end
end
