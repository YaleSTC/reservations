class AddDisableRequestsToAppConfigs < ActiveRecord::Migration
  def change
    add_column :app_configs, :disable_requests, :boolean, default: false
  end
end
