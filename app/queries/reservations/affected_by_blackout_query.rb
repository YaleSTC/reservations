# frozen_string_literal: true

module Reservations
  class AffectedByBlackoutQuery < Reservations::ReservationsQueryBase
    def call(blackout)
      date_range = blackout.start_date..blackout.end_date
      @relation.unscoped.where(start_date: date_range)
               .or(@relation.unscoped.where(due_date: date_range)).active
    end
  end
end
