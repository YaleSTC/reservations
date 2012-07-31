class AddSettingsToAppConfig < ActiveRecord::Migration
  def up
    add_column :app_configs, :site_title, :string
    add_column :app_configs, :admin_email, :string
    add_column :app_configs, :department_name, :string
    add_column :app_configs, :contact_link_text, :string
    add_column :app_configs, :contact_link_location, :string
    add_column :app_configs, :home_link_text, :string
    add_column :app_configs, :home_link_location, :string
    add_column :app_configs, :default_per_cat_page, :integer
    add_column :app_configs, :upcoming_checkin_email_body, :text
    add_column :app_configs, :overdue_checkout_email_body, :text
    add_column :app_configs, :overdue_checkin_email_body, :text   
  end
  
  def down
    remove_column :app_configs, :site_title
    remove_column :app_configs, :admin_email
    remove_column :app_configs, :department_name
    remove_column :app_configs, :contact_link_text
    remove_column :app_configs, :contact_link_location
    remove_column :app_configs, :home_link_text
    remove_column :app_configs, :home_link_location
    remove_column :app_configs, :default_per_cat_page
    remove_column :app_configs, :upcoming_checkin_email_body
    remove_column :app_configs, :overdue_checkout_email_body
    remove_column :app_configs, :overdue_checkin_email_body
  end
  
end
