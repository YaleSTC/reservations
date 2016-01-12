module Reservations
  class CheckoutableQuery < Reservations::ReservationsQueryBase
    def call
      @relation.where('start_date <= ?', Time.zone.today).reserved
    end
  end
end
