class AddMissedReservationDeletedEmailBodyToAppConfigs < ActiveRecord::Migration
  def change
    add_column :app_configs, :deleted_missed_reservation_email_body, :text
    
    app_config = AppConfig.first
    
    if app_config
      app_config.deleted_missed_reservation_email_body = "Dear @user@,\nBecause you have missed a scheduled equipment checkout, your reservation has been cancelled. If you believe this is in error, please contact an administrator.\n\nThank you,\n@department_name@"
      app_config.save
    end

  end
end
