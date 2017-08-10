# frozen_string_literal: true

module Reservations
  class UpcomingQuery < Reservations::ReservationsQueryBase
    def call
      @relation.unscoped.where(start_date: Time.zone.today).reserved
               .order('reserver_id')
    end
  end
end
