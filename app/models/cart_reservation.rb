class CartReservation < Reservation
  validate :not_in_past?, :not_empty?


end
