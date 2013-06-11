class AddDeleteMissedReservationsToAppConfigs < ActiveRecord::Migration
  def change
    add_column :app_configs, :delete_missed_reservations, :boolean, default: true
  end
end
