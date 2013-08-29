class AddRequirePhoneToAppConfigs < ActiveRecord::Migration
  def up
  	add_column :app_configs, :require_phone, :boolean, :default => true
  end
  def down
  	remove_column :app_configs, :require_phone
  end
end
