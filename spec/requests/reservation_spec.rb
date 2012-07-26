require 'spec_helper'

describe 'reservation' do
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

  it 'passes/fails no_overdue_reservations? correctly' do
    res.no_overdue_reservations?.should == true
    overdue_res = FactoryGirl.build(:overdue_reservation, reserver: admin)
    overdue_res.save(:validate => false)
    res.no_overdue_reservations?.should == false
    #res.save.should == false
  end

  it 'passes/fails start_date_before_due_date? correctly' do
    res.start_date_before_due_date?.should == true
    res.due_date = Date.yesterday
    res.start_date_before_due_date?.should == false
    res.due_date = Date.tomorrow
    #res.save.should == false
  end

  it 'passes/fails not_in_past? correctly'do
    res.not_in_past?.should == true
    res.start_date = Date.yesterday
    res.not_in_past?.should == false
    overdue_res = FactoryGirl.build(:overdue_reservation)
    overdue_res.save(:validate => false)
    overdue_res.not_in_past?.should == true #not_in_past ignores missed/overdue reservations
    checked_out_res = FactoryGirl.create(:checked_out_reservation)
    checked_out_res.not_in_past?.should == true #not_in_past ignores checked in/checked out reservations
    #res.save.should == false
  end

  it 'passes/fails not_empty? correctly' do
    res.not_empty?.should == true
    res.equipment_model = nil
    res.not_empty?.should == false
    #res.save.should == false
  end

  it 'passes/fails matched_object_and_model? correctly' do
    res.matched_object_and_model?.should == true #no assigned object
    res.equipment_object = obj
    res.matched_object_and_model?.should == true
    res.equipment_model = FactoryGirl.create(:equipment_model)
    res.matched_object_and_model?.should == false
    #res.save.should == false
  end

  it 'passes/fails not_renewable? correctly' do
    res.not_renewable?.should == true
    renew = FactoryGirl.build(:checked_out_reservation)
    renew.save
    renew_user = User.find(renew.reserver_id)
    renew_mod = renew.equipment_model
    res2 = Reservation.new(reserver: renew_user, start_date: renew.due_date, due_date: renew.due_date.tomorrow)
    res2.equipment_model = renew_mod
    res2.not_renewable?.should == false
#    res2.save.should? == false
  end

  it 'passes/fails duration_allowed? correctly' do
    res.duration_allowed?.should == true
    allowed_duration = eq.category.max_checkout_length
    res.due_date = Date.tomorrow + allowed_duration
    res.duration_allowed?.should == false
#    res.save.should? == false
  end

end
