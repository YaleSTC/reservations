class AddNotesToEquipmentObjects < ActiveRecord::Migration
  def change
    add_column :equipment_objects, :notes, :text, limit: 16777215, null: false

    # Add code here to go through all existing equipment objects, their reservations in sequential order, and generate notes for checkin and checkout for all old reservations
    # potentially make the `make_reservation_notes` method take the time/date as a parameter so that we can use it here.
  end
end
