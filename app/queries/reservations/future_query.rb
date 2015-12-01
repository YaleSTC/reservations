module Reservations
  class FutureQuery < Reservations::ReservationsQueryBase
    def call
      @relation.where('start_date > ?', Time.zone.today.beginning_of_day)
        .reserved
    end
  end
end
