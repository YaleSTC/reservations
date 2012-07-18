class CartReservation < Reservation
  belongs_to :equipment_model
  belongs_to :reserver, :class_name => 'User'

  validate :not_in_past?, :not_empty?
end
