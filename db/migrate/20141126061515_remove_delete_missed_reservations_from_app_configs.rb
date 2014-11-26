class RemoveDeleteMissedReservationsFromAppConfigs < ActiveRecord::Migration
  def change
    remove_column :app_configs, :delete_missed_reservations
  end
end
