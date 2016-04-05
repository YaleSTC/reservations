class AddAutodeactivateOnArchiveToAppConfig < ActiveRecord::Migration
  def change
    add_column :app_configs, :autodeactivate_on_archive, :boolean, default: false
  end
end
