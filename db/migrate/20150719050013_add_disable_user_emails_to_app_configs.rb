class AddDisableUserEmailsToAppConfigs < ActiveRecord::Migration
  def change
    add_column :app_configs, :disable_user_emails, :boolean, default: false
  end
end
