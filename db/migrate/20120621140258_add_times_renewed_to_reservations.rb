class AddTimesRenewedToReservations < ActiveRecord::Migration
  def change
    add_column :reservations, :times_renewed, :integer

  end
end
