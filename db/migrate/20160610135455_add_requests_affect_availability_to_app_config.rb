class AddRequestsAffectAvailabilityToAppConfig < ActiveRecord::Migration[4.2]
  def change
    add_column :app_configs, :requests_affect_availability, :boolean, default: false
  end
end
