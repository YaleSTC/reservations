class AddEmailActiveForAppConfigs < ActiveRecord::Migration
  def up
    add_column :app_configs, :overdue_checkin_email_active, :boolean, :default => true
  end

  def down
    remove_column :app_configs, :overdue_checkin_email_active
  end
end
