class AddCheckoutPersonCanOverrideToAppConfigs < ActiveRecord::Migration
  def change
  	add_column :app_configs, :override_on_create, :boolean, :default => false
  	add_column :app_configs, :override_at_checkout, :boolean, :default => false
  end
end
