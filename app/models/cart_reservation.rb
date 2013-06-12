class CartReservation < ActiveRecord::Base
  include ReservationsBase
  include ReservationValidations

  validates :reserver,
            :start_date,
            :due_date,
            :presence => true

  validate :not_in_past?, :not_empty?
end
