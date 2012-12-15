class AddSendNotificationsForDeletedMissedReservationsToAppConfigs < ActiveRecord::Migration
  def change
    add_column :app_configs, :send_notifications_for_deleted_missed_reservations, :boolean, default: true
  end
end
