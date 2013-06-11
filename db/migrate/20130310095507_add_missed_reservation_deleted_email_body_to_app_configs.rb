class AddMissedReservationDeletedEmailBodyToAppConfigs < ActiveRecord::Migration
  def change
    add_column :app_configs, :deleted_missed_reservation_email_body, :text
    
    app_config = AppConfig.first
    
    if app_config
      app_config.deleted_missed_reservation_email_body = "Dear @user@,

Equipment reserved for reservation \#@reservation_id@ was due to be picked up on @start_date@  but was not picked up. This reservation has been cancelled. 

The following items were not picked up:

@equipment_list@

If you believe this is in error, please contact an administrator.

Thank you,
@department_name@"
      app_config.save
    end

  end
end
