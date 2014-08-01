class AddRequestTextToAppConfigs < ActiveRecord::Migration
  def change
    add_column :app_configs, :request_text, :text
  end
end
