class AddNotesToEquipmentObjects < ActiveRecord::Migration
  def change
    add_column :equipment_objects, :notes, :text, limit: 16777215, null: false

    # go through all existing equipment objects, including reservations and
    # associated users
    EquipmentObject.includes(reservations: [:reserver, :checkout_handler, :checkin_handler]).all.each do |eo|
      # add creation note
      eo.update_attributes(notes: "#### Created at #{eo.created_at.to_s(:long)}")
      # go through all reservations and make notes
      eo.reservations.sort_by(&:checked_out).each do |res|
        eo.make_reservation_notes('checked_out', res, res.checkout_handler, '', res.checked_out) if res.checked_out
        eo.make_reservation_notes('checked_in', res, res.checkin_handler, '', res.checked_in) if res.checked_in
      end
    end
  end
end
