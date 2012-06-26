class AddAppConfigTable < ActiveRecord::Migration
  def up
     create_table :app_configs do |t|
        t.boolean :upcoming_checkin_email_active, :default => true
        t.boolean :overdue_checkout_email_active, :default => true
        t.boolean :overdue_checkout_email_active, :default => true
        t.boolean :reservation_confirmation_email_active, :default => true
      end
  end

  def down
    drop_table :app_configs
  end
end
