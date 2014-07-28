class AddMaxCheckoutLengthToEquipmentModels < ActiveRecord::Migration
  def change
    add_column :equipment_models, :max_checkout_length, :integer
  end
end
