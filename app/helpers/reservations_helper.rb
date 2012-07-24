module ReservationsHelper
  def reservation_length
   @reservation_length = (@reservation.due_date.to_date - @reservation.start_date.to_date).to_i
  end
end
