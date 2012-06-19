class CleanUpCheckInOutProcedures < ActiveRecord::Migration
  def change
    remove_column :equipment_models, :checkout_procedures
    remove_column :equipment_models, :checkin_procedures
  end
end