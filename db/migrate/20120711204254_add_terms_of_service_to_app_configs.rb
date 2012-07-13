class AddTermsOfServiceToAppConfigs < ActiveRecord::Migration
  def self.up
    add_column :app_configs, :terms_of_service, :text
  end

  def self.down
    remove_column :app_configs, :terms_of_service
  end
end
