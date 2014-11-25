class AddEnableNewUsersToAppConfigs < ActiveRecord::Migration
  def change
    add_column :app_configs, :enable_new_users, :boolean, default: true
  end
end
