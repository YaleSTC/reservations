class CreateReservations < ActiveRecord::Migration
  def self.up
    create_table :reservations do |t|
      t.references :reserver
      t.references :checkout_handler
      t.references :checkin_handler
      t.datetime :start_date
      t.datetime :due_date
      t.datetime :checked_out
      t.datetime :checked_in
      t.timestamps
    end
  end
  
  def self.down
    drop_table :reservations
  end
end
