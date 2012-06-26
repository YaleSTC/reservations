class AddRenewalPrefsCategories < ActiveRecord::Migration
  def up
    add_column :categories, :max_renewal_times, :integer
    add_column :categories, :max_renewal_length, :integer
    add_column :categories, :renewal_days_before_due, :integer
  end
  
  def down
    remove_column :categories, :max_renewal_times, :integer
    remove_column :categories, :max_renewal_length, :integer
    remove_column :categories, :renewal_days_before_due, :integer
  end
end
