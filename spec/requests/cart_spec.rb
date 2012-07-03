require 'spec_helper'

describe 'remove_item' do

  it 'only removes one copy of the reservation and not all the ones that have the same equipment model' do
    r = Reservation.new(:start_date => Date.today, :due_date => Date.today)
    items = []
    items << r
    items << r
    items.delete_at(items.index(r))
    items.length.should == 1
  end
end


