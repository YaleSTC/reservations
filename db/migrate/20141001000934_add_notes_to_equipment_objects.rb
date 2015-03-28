class AddNotesToEquipmentObjects < ActiveRecord::Migration
  def change
    add_column :equipment_objects, :notes, :text, limit: 16_777_215, null: false

    # go through all existing equipment items, including reservations and
    # associated users
    EquipmentItem.table_name = 'equipment_objects' # deal with renamed model
    EquipmentItem.all.each do |ei|
      # add creation note
      ei.update_attributes notes: "#### Created at #{ei.created_at.to_s(:long)}"
      # go through all reservations and make notes
      Reservation.includes(:reserver, :checkout_handler, :checkin_handler)
        .where('equipment_object_id = ?', ei.id)
        .sort_by(&:checked_out).each do |res|
        ei.make_reservation_notes('checked_out', res, res.checkout_handler,
                                  '', res.checked_out) if res.checked_out
        ei.make_reservation_notes('checked_in', res, res.checkin_handler,
                                  '', res.checked_in) if res.checked_in
      end
    end
  end
end
