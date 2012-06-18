class CleanUpOldCheckinCheckoutProcedures < ActiveRecord::Migration
  def up
    remove_column("equipment_models", "checkin_procedures")
    remove_column("equipment_models", "checkout_procedures")
  end

  def down
    add_column("equipment_models", "checkin_procedures", :string)
    add_column("equipment_models", "checkout_procedures", :string)
  end
end
