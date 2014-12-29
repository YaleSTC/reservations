class AddResExpTimeToAppConfigs < ActiveRecord::Migration
  def change
    add_column :app_configs, :res_exp_time, :integer
  end
end
