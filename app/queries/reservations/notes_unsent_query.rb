# frozen_string_literal: true
module Reservations
  class NotesUnsentQuery < Reservations::ReservationsQueryBase
    def call
      @relation.where(notes_unsent: true).where.not(notes: nil)
    end
  end
end
