# Note, this migration was moved forward in time (timestamp) to fix bug with
# next migration (combine_type_columns_in_users_table) which referenced this
# attr through the user model.

class AddRequirePhoneToAppConfigs < ActiveRecord::Migration
  def up
  	add_column :app_configs, :require_phone, :boolean, :default => true
  end
  def down
  	remove_column :app_configs, :require_phone
  end
end
