class AddPatronsCanRenewToAppConfig < ActiveRecord::Migration
  def change
    add_column :app_configs, :patrons_can_renew, :boolean, default: true
  end
end
