class AddAutodeactivateOnArchiveToAppConfig < ActiveRecord::Migration[4.2]
  def change
    add_column :app_configs, :autodeactivate_on_archive, :boolean, default: false
  end
end
