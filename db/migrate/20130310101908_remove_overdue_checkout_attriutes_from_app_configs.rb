class RemoveOverdueCheckoutAttriutesFromAppConfigs < ActiveRecord::Migration
  def up
    remove_column :app_configs, :overdue_checkout_email_active
    remove_column :app_configs, :overdue_checkout_email_body
  end

  def down
    add_column :app_configs, :overdue_checkout_email_active, :default => true
    add_column :app_configs, :overdue_checkout_email_body, :text
  end
end
