module Reservations
  class StartsOnDaysQuery < Reservations::ReservationsQueryBase
    def call(start_date, end_date)
      @relation.where(start_date: start_date..end_date)
    end
  end
end
