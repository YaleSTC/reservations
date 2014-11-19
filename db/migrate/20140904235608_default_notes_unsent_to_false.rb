class DefaultNotesUnsentToFalse < ActiveRecord::Migration
  def change
    change_column :reservations, :notes_unsent, :boolean, :default => false
  end
end
