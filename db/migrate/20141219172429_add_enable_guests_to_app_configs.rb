class AddEnableGuestsToAppConfigs < ActiveRecord::Migration
  def change
    add_column :app_configs, :enable_guests, :boolean, default: true
  end
end
