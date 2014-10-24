class AddEnableRenewalsToAppConfig < ActiveRecord::Migration
  def change
    add_column :app_configs, :enable_renewals, :boolean, default: true
  end
end
