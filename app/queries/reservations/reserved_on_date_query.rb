module Reservations
  class ReservedOnDateQuery < Reservations::ReservationsQueryBase
    def call(date)
      @relation.where('start_date <= ? and due_date >= ?', date, date).active
    end
  end
end
