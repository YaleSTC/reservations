class AddNotifyAdminOnCreateToAppConfig < ActiveRecord::Migration
  def change
    add_column :app_configs, :notify_admin_on_create, :boolean, default: false
  end
end
