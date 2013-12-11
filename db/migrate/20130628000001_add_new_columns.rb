# Note, this migration was moved forward in time (timestamp) to fix bug with
# next migration (combine_type_columns_in_users_table) which referenced this
# attr through the user model.

class AddNewColumns < ActiveRecord::Migration
  def up
  	add_column :app_configs, :require_phone, :boolean, :default => false
    add_column :users, :view_mode, :string, :default => 'admin'
    add_column :app_configs, :viewed, :boolean, :default => true
    add_column :app_configs, :override_on_create, :boolean, :default => false
    add_column :app_configs, :override_at_checkout, :boolean, :default => false
    add_column :checkin_procedures, :deleted_at, :datetime
    add_column :checkout_procedures, :deleted_at, :datetime
  end

  def down
  	remove_column :app_configs, :require_phone
    remove_column :users, :view_mode
    remove_column :app_configs, :viewed
    remove_column :app_configs, :override_on_create, :boolean, :default => false
    remove_column :app_configs, :override_at_checkout, :boolean, :default => false
    remove_column :checkin_procedures, :deleted_at, :datetime
    remove_column :checkout_procedures, :deleted_at, :datetime
  end
end
