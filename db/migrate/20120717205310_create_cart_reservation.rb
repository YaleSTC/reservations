class CreateCartReservation < ActiveRecord::Migration
  def up
    create_table :cart_reservations do |t|
      t.references :reserver
      t.datetime :start_date
      t.datetime :due_date
      t.references :equipment_model
      t.timestamps
    end
  end

  def down
    drop_table :cart_reservations
  end
end
