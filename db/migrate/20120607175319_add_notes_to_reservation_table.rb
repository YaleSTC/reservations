class AddNotesToReservationTable < ActiveRecord::Migration
  def self.up
    add_column :reservations, :notes, :text
  end

  def self.down
    remove_column :reservations, :notes
  end
end
