module Reservations
  class FutureQuery < Reservations::ReservationsQueryBase
    def call
      @relation.where('start_date > ?', Time.zone.today.to_time).reserved
    end
  end
end
