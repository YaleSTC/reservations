class AddCheckoutPersonsCanEditToAppConfigs < ActiveRecord::Migration
  def change
    add_column :app_configs, :checkout_persons_can_edit, :boolean, :default => false
  end
end

