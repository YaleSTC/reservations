module Reservations
  class UpcomingQuery < Reservations::ReservationsQueryBase
    def call
      @relation.unscoped.today_date(:start_date).reserved.order('reserver_id')
    end
  end
end
