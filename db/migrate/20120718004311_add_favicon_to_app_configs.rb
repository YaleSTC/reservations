class AddFaviconToAppConfigs < ActiveRecord::Migration
  def up
    add_attachment :app_configs, :favicon
  end

  def down
    remove_attachment :app_configs, :favicon
  end
end