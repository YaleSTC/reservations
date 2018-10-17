# frozen_string_literal: true

module Reservations
  class AffectedByRecurringBlackoutQuery < ReservationsQueryBase
    def call(res_dates)
      @relation.where(due_date: res_dates)
               .or(Reservation.where(start_date: res_dates)).active
    end
  end
end
