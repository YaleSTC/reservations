module Reservations
  class ReservationsQueryBase < QueryBase
    def initialize(relation = Reservation.all)
      @relation = relation
    end
  end
end
