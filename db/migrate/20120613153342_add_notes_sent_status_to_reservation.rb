class AddNotesSentStatusToReservation < ActiveRecord::Migration
  def self.up
    add_column :reservations, :notes_unsent, :boolean, :default => true
  end

  def self.down
    remove_column :reservations, :notes_unsent
  end
end
