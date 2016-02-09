module Reservations
  class OverlapsWithDateRangeQuery < Reservations::ReservationsQueryBase
    def call(start_date, end_date)
      @relation
        .where('start_date <= ? and due_date >= ?', end_date, start_date)
    end
  end
end
