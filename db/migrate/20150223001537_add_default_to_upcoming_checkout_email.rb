class AddDefaultToUpcomingCheckoutEmail < ActiveRecord::Migration
  def change
    change_column_default :app_configs, :upcoming_checkout_email_active, true
  end
end
