class AddPositionToCheckinProcedures < ActiveRecord::Migration
  def change
    add_column :checkin_procedures, :position, :integer
  end
end
