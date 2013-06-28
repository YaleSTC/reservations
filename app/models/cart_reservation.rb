class CartReservation < ActiveRecord::Base
  include ReservationsBase
  include ReservationValidations

  validate :not_in_past?, :not_empty?
end
