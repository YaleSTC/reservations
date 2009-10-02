require 'test_helper'

class ReservationTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert Reservation.new.valid?
  end
end
