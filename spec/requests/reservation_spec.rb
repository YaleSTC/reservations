require 'spec_helper'

describe 'reservation' do
  CartReservation.delete_all
  User.delete_all
  EquipmentObject.delete_all
  EquipmentModel.delete_all
  Reservation.delete_all

  admin = FactoryGirl.create(:admin)
  mod = FactoryGirl.create(:equipment_model_with_object)
  obj = mod.equipment_objects.first
  res = Reservation.new(reserver: admin, start_date: Date.today, due_date: Date.tomorrow)
  res.equipment_model = mod

  it 'can be created' do
    res.save.should == true
    Reservation.all.size.should == 1
    Reservation.all.first.should == res
  end

  it 'passes/fails no_overdue_reservations? correctly' do
    res.no_overdue_reservations?.should == true
    overdue_res = FactoryGirl.build(:overdue_reservation, reserver: admin)
    overdue_res.save(:validate => false)
    res.no_overdue_reservations?.should == false
    res.save.should == false
    Reservation.delete(overdue_res.id)
    res.save.should == true
  end

  it 'passes/fails start_date_before_due_date? correctly' do
    res.start_date_before_due_date?.should == true
    res.due_date = Date.yesterday
    res.start_date_before_due_date?.should == false
    res.save.should == false
    res.due_date = Date.tomorrow
    res.save.should == true
  end

  it 'passes/fails not_in_past? correctly'do
    res.not_in_past?.should == true
    res.start_date = Date.yesterday
    res.not_in_past?.should == false
    overdue_res = FactoryGirl.build(:overdue_reservation)
    overdue_res.save(:validate => false)
    overdue_res.not_in_past?.should == true #not_in_past ignores missed/overdue reservations
    checked_out_res = FactoryGirl.build(:checked_out_reservation)
    checked_out_res.save(:validate => false)
    checked_out_res.not_in_past?.should == true #not_in_past ignores checked in/checked out reservations
    res.save.should == false
    res.start_date = Date.today
    res.save.should == true
  end

  it 'passes/fails not_empty? correctly' do
    res.not_empty?.should == true
    res.equipment_model = nil
    res.not_empty?.should == false
    res.save.should == false
    res.equipment_model = mod
    res.save.should == true
  end

  it 'passes/fails matched_object_and_model? correctly' do
    res.equipment_model = mod
    res.matched_object_and_model?.should == true #no assigned object
    res.equipment_object = FactoryGirl.create(:equipment_object)
    res.matched_object_and_model?.should == false
    res.save.should == false
    res.equipment_model = res.equipment_object.equipment_model
    res.matched_object_and_model?.should == true
    res.equipment_object = nil
    res.equipment_model = mod
    res.save.should == true
  end

  it 'passes/fails not_renewable? correctly' do
    res.not_renewable?.should == true
    renew = FactoryGirl.build(:checked_out_reservation)
    renew.save(:validate => false)
    renew_user = User.find(renew.reserver_id)
    renew_mod = renew.equipment_model
    res_renew = Reservation.new(reserver: renew_user, start_date: renew.due_date, due_date: renew.due_date.tomorrow)
    res_renew.equipment_model = renew_mod
    res_renew.not_renewable?.should == false
    res_renew.save.should == false
    Reservation.delete(res_renew.id)
    Reservation.delete(renew.id)
  end

  it 'passes/fails duration_allowed? correctly' do
    res.duration_allowed?.should == true
    allowed_duration = mod.category.maximum_checkout_length
    res.due_date = Date.tomorrow + allowed_duration
    res.duration_allowed?.should == false
    res.save.should == false
    res.due_date = Date.tomorrow
  end

  it 'passes/fails available? correctly' do
    available_res = FactoryGirl.build(:reservation)
    available_res.save.should == true
    available_res.available?.should == true
    overdue_res = FactoryGirl.build(:overdue_reservation)
    overdue_res.save(:validate => false)
    overdue_res.available?.should == true
    checked_out_res = FactoryGirl.build(:checked_out_reservation)
    checked_out_res.save(:validate => false)
    checked_out_res.available?.should == true
    res_unavailable = Reservation.new(reserver: admin, start_date: Date.today, due_date: Date.tomorrow)
    res_unavailable.equipment_model = FactoryGirl.create(:equipment_model)
    res_unavailable.equipment_model.equipment_objects.size.should == 0
    res_unavailable.save(:validate => false)
    res_unavailable.available?.should == false
    res_unavailable.save.should == false
  end

  it 'passes/fails quantity_eq_model_allowed? correctly' do
    max_mod = FactoryGirl.create(:equipment_model, max_per_user: 1)
    max_res = FactoryGirl.build(:reservation, reserver: admin, equipment_model: max_mod)
    max_res.save(:validate => false)
    max_res.quantity_eq_model_allowed?.should == true
    max_res2 = FactoryGirl.build(:reservation, reserver: admin, equipment_model: max_mod)
    max_res2.save(:validate => false)
    max_res.quantity_eq_model_allowed?.should == false
    max_res2.save.should == false
    unrestricted_mod = FactoryGirl.create(:equipment_model, max_per_user: nil)
    unrestricted_res = FactoryGirl.build(:reservation, reserver: admin, equipment_model: unrestricted_mod)
    unrestricted_res.save(:validate => false)
    unrestricted_res.quantity_eq_model_allowed?.should == true
  end

  it 'passes/fails quantity_cat_allowed? correctly' do
    Reservation.delete_all
    EquipmentModel.delete_all
    max_cat = FactoryGirl.create(:category, max_per_user: 1)
    max_mod = FactoryGirl.create(:equipment_model, category: max_cat)
    max_res = FactoryGirl.build(:reservation, reserver: admin, equipment_model: max_mod)
    max_res.save(:validate => false)
    max_res.equipment_model.category.maximum_per_user.should == 1
    max_res.quantity_cat_allowed?.should == true
    max_res2 = FactoryGirl.build(:reservation, reserver: admin, equipment_model: max_mod)
    max_res2.save(:validate => false)
    max_res2.quantity_cat_allowed?.should == false
    max_res2.save.should == false
    unrestricted_cat = FactoryGirl.create(:category, max_per_user: nil)
    unrestricted_mod = FactoryGirl.create(:equipment_model, category: unrestricted_cat)
    unrestricted_res = FactoryGirl.build(:reservation, reserver: admin, equipment_model: unrestricted_mod)
    unrestricted_res.save(:validate => false)
    unrestricted_res.quantity_cat_allowed?.should == true
  end

  it 'creates correct errors for validate_set' do
    Reservation.delete_all
    EquipmentModel.delete_all
    Reservation.validate_set(admin).should == []
    res = FactoryGirl.build(:reservation, reserver: admin)
    res.save(:validate => false)
    Reservation.validate_set(admin).should == []
    overdue_res = FactoryGirl.build(:overdue_reservation, reserver: admin)
    overdue_res.save(:validate => false)
    Reservation.validate_set(admin).should == ["User has overdue reservations that prevent new ones from being created"]
  end
end
