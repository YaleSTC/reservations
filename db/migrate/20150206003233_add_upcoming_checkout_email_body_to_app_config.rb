class AddUpcomingCheckoutEmailBodyToAppConfig < ActiveRecord::Migration
  def change
    add_column :app_configs, :upcoming_checkout_email_body, :text
  end
end
