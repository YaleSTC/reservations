class AddOverdueToReservation < ActiveRecord::Migration
  def change
    add_column :reservations, :overdue, :boolean, default: false
  end
end
