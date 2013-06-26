require 'spec_helper'

describe CartReservation do
  before(:each) do
    @cr = FactoryGirl.build(:cart_reservation)
  end
  it "has a working factory" do
    @cr.should be_valid
  end
end
