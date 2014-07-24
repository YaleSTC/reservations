class ChangeReservationDueDatesTo12359 < ActiveRecord::Migration
  def up
    Reservation.all.each do |r|
      r.save
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
