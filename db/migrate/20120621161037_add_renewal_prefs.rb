class AddRenewalPrefs < ActiveRecord::Migration
  def up
    add_column :equipment_models, :max_renewal_times, :integer
    add_column :equipment_models, :max_renewal_length, :integer
    add_column :equipment_models, :renewal_days_before_due, :integer
  end
  
  def down
    remove_column :equipment_models, :max_renewal_times, :integer
    remove_column :equipment_models, :max_renewal_length, :integer
    remove_column :equipment_models, :renewal_days_before_due, :integer
  end
end
