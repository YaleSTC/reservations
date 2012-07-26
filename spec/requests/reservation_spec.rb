require 'spec_helper'

describe 'reservations' do
  CartReservation.delete_all
  User.delete_all
  EquipmentObject.delete_all
  EquipmentModel.delete_all
  Reservation.delete_all

  admin = FactoryGirl.create(:admin)
  obj = FactoryGirl.create(:equipment_object)
  mod = obj.equipment_model
  res = Reservation.new(reserver: admin, start_date: Date.today, due_date: Date.tomorrow)
  res.equipment_model = mod


  it 'can be created' do
    res.save.should == true
  end

  it 'pass/fail no_overdue_reservations? correctly' do
    res.no_overdue_reservations?.should == true
    overdue_res = FactoryGirl.build(:overdue_reservation, reserver: admin)
    overdue_res.save(:validate => false)
    res.no_overdue_reservations?.should == false
    #res.save.should == false
  end

  it 'pass/fail start_date_before_due_date? correctly' do
    res.start_date_before_due_date?.should == true
    res.due_date = Date.yesterday
    res.start_date_before_due_date?.should == false
    res.due_date = Date.tomorrow
    #res.save.should == false
  end

  it 'pass/fail not_in_past? correctly'do
    res.not_in_past?.should == true
    res.start_date = Date.yesterday
    binding.pry
    res.not_in_past?.should == false
    overdue_res = FactoryGirl.build(:overdue_reservation)
    overdue_res.save(:validate => false)
    overdue_res.not_in_past?.should == true #not_in_past ignores missed/overdue reservations
    checked_out_res = FactoryGirl.create(:checked_out_reservation)
    checked_out_res.not_in_past?.should == true #not_in_past ignores checked in/checked out reservations
    #res.save.should == false
  end
end
