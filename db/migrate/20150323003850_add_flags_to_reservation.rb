class AddFlagsToReservation < ActiveRecord::Migration
  def change
    add_column :reservations, :flags, :integer, default: 1
  end
end
