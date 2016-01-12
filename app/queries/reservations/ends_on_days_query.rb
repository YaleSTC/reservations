module Reservations
  class EndsOnDaysQuery < Reservations::ReservationsQueryBase
    def call(start_date, end_date)
      @relation.where(due_date: start_date..end_date)
    end
  end
end
