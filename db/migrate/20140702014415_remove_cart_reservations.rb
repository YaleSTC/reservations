class RemoveCartReservations < ActiveRecord::Migration
  def up
    drop_table :cart_reservations
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
