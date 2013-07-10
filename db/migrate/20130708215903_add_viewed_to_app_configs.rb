class AddViewedToAppConfigs < ActiveRecord::Migration
  def up
    add_column :app_configs, :viewed, :boolean, :default => true
  end
  def down
    remove_column :app_configs, :viewed
  end
end
