class AddContactLinkEmailToAppConfigs < ActiveRecord::Migration
  def change
    remove_column :app_configs, :contact_link_text
  end
  
end