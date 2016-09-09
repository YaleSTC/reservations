# frozen_string_literal: true
module Reservations
  class ReservationsQueryBase < QueryBase
    def initialize(relation = Reservation.all)
      @relation = relation
    end
  end
end
