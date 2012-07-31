class CartReservation < ActiveRecord::Base
  include ReservationValidations

  validates :reserver,
            :start_date,
            :due_date,
            :presence => true

  validate :not_in_past?, :not_empty?
end
