class AddApprovalStatusColumnToReservations < ActiveRecord::Migration
  def change
    add_column :reservations, :approval_status, :text, :default => 'auto'
  end
end
