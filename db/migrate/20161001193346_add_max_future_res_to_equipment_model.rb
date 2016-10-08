class AddMaxFutureResToEquipmentModel < ActiveRecord::Migration
  def change
    add_column :equipment_models, :max_future_res, :integer, default: nil
  end
end
