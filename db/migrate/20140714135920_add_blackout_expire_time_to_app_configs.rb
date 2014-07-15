class AddBlackoutExpireTimeToAppConfigs < ActiveRecord::Migration
  def change
    add_column :app_configs, :blackout_exp_time, :integer
  end
end
