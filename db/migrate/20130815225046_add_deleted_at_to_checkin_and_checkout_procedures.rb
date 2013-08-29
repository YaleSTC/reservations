class AddDeletedAtToCheckinAndCheckoutProcedures < ActiveRecord::Migration
  def change
  	add_column :checkin_procedures, :deleted_at, :datetime
  	add_column :checkout_procedures, :deleted_at, :datetime
  end
end
