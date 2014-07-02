class AddApprovalStatusColumnToReservations < ActiveRecord::Migration
  def change
    add_column :reservations, :approval_status, :string, :default => 'auto'
  end
end
