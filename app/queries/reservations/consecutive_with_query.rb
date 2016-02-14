module Reservations
  class ConsecutiveWithQuery < Reservations::ReservationsQueryBase
    def call(start_date, due_date)
      @relation.where('start_date = ? OR due_date = ?', due_date + 1.day,
                      start_date - 1.day).active
    end
  end
end
