require 'spec_helper'

describe 'cart' do
  CartReservation.delete_all
  User.delete_all
  EquipmentObject.delete_all
  EquipmentModel.delete_all

  admin = FactoryGirl.create(:admin)
  cart = Cart.new
  cart.set_reserver_id(admin.id)
  eq = FactoryGirl.create(:equipment_model)
  cart.add_item(eq)

  it 'initializes' do
    cart.start_date
    cart.due_date
    cart.reserver
  end

  it 'add_item works' do
    cart.add_item(eq)
    cart.items.size.should == 2
    CartReservation.all.size.should == 2
    CartReservation.find(cart.items.first).equipment_model.should == eq
    cart.items.first.should_not == cart.items.last
    CartReservation.find(cart.items.last).equipment_model.should == eq
  end

  it 'remove_item works' do
    cart.remove_item(eq)
    cart.items.size.should == 1
    CartReservation.all.size.should == 1
  end

  it 'not_empty? works when called on reservations in @items' do
    res.equipment_model = nil
    res.not_empty?.should == false
    res.equipment_model = eq
    res.not_empty?.should == true
  end

  it 'not_in_past? works when called on reservations in @items' do
    res.due_date = Date.yesterday
    res.not_in_past?.should == false
    res.due_date = Date.today
    res.not_in_past?.should == true
    res.start_date = Date.yesterday
    res.not_in_past?.should == false
    res.start_date = Date.today
    res.not_in_past?.should == true
  end

  it 'start_date_before_due_date? works when called on reservations in @items' do
    res.due_date = Date.yesterday
    res.start_date_before_due_date?.should == false
    res.due_date = Date.today
    res.start_date_before_due_date?.should == true
  end

  #fix this test
  it 'not_renewable? works when called on reservations in @items' do
    res.not_renewable?.should == true
    renew = FactoryGirl.create(:checked_out_reservation, reserver: admin)
    res.not_renewable?.should == false
  end

  it 'no_overdue_reservations? works when called on reservations in @items' do
    res.no_overdue_reservations?.should == true
    overdue = FactoryGirl.create(:overdue_reservation, reserver: admin)
    res.no_overdue_reservations?.should == false
  end

  it 'duration_allowed? works when called on reservations in @items' do
    res.duration_allowed?.should == true
    allowed_duration = eq.category.max_checkout_length
    cart.set_due_date(Date.tomorrow + allowed_duration)
    cart.add_item(eq)
    res1 = cart.items.last
    res1.duration_allowed?.should == false
  end

  it 'count works when called on reservations in @items' do
    res.count(cart.items).should == 2
    eq2 = FactoryGirl.create(:equipment_model)
    cart.add_item(eq2)
    res2 = cart.items.last
    res2.count(cart.items).should == 1
    cart.remove_item(eq2)
    res2.count(cart.items).should == 0
  end

  it 'available? works when called on reservations in @items' do
    res.available?.should == false
    obj = FactoryGirl.create(:equipment_object)
    mod_obj = obj.equipment_model
    cart.add_item(mod_obj)
    res_obj = cart.items.last
    res_obj.available?.should == true
    cart.add_item(mod_obj)
    res_obj.available?.should == true #can only see 1 without cart.items
    res_obj.available?(cart.items).should == false
  end

  it 'quantity_eq_model_allowed?" works when called on reservations in @items' do
    eq_max = FactoryGirl.create(:equipment_model, max_per_user: 1)
    cart.add_item(eq_max)
    res_max = cart.items.last
    res_max.quantity_eq_model_allowed?.should == true
    res_max.quantity_eq_model_allowed?(cart.items).should == true
    cart.add_item(eq_max)
    res_max.quantity_eq_model_allowed?.should == true #without cart.items it can only see 1
    res_max.quantity_eq_model_allowed?(cart.items).should == false
  end

  it 'quantity_cat_allowed? works when called on reservations in @items' do
    cat_max = FactoryGirl.create(:category, max_per_user: 1)
    eq_cat_max = FactoryGirl.create(:equipment_model, category: cat_max)
    cart.add_item(eq_cat_max)
    res_cat_max = cart.items.last
    res_cat_max.quantity_cat_allowed?.should == true
    res_cat_max.quantity_cat_allowed?(cart.items).should == true
    cart.add_item(eq_cat_max)
    res_cat_max.quantity_cat_allowed?.should == true #doesn't know about cart.items
    res_cat_max.quantity_cat_allowed?(cart.items).should == false
  end

  it 'changing reserver_id changes the reserver for the cart items' do
    user = FactoryGirl.create(:user)
    cart.set_reserver_id(user.id)
    res = cart.items.first
    res.reserver_id.should == user.id
    res.reserver.should == user
    cart.set_reserver_id(admin.id)
    res.reserver.should == admin
  end

  it 'changing dates changes the reservation dates' do
    cart.set_start_date(Date.tomorrow)
    cart.set_due_date(Date.tomorrow + 1)
    cart.start_date.should == Date.tomorrow
    cart.due_date.should == Date.tomorrow + 1
    res = cart.items.first
    res.start_date.to_date.should == Date.tomorrow
    res.due_date.to_date.should == Date.tomorrow + 1
  end

  #TODO: could write more tests for failure... probs not necessary
  it 'valid? works when called reservations in @items' do
    cart.items.clear
    cart.set_start_date(Date.today)
    cart.set_due_date(Date.tomorrow)
    obj = FactoryGirl.create(:equipment_object)
    eq_valid = obj.equipment_model
    cart.add_item(eq_valid)
    res = cart.items.first
    res.valid?.should == true
    r = Reservation.new(reserver: admin, start_date: Date.tomorrow, due_date: Date.yesterday)
    r.equipment_model = eq
    r.start_date_before_due_date?.should == false
    r.not_in_past?.should == false
    r.valid?.should == false
  end

  #TODO: write tests for all the errors (?)
  it 'validate_set works when called on reservations in @items' do
    cart.items.clear
    Reservation.validate_set(admin, cart.items).should == []
    cart.set_start_date(Date.today)
    cart.set_due_date(Date.tomorrow)
    obj = FactoryGirl.create(:equipment_object)
    eq_valid = obj.equipment_model
    cart.add_item(eq_valid)
    Reservation.validate_set(admin, cart.items).should == []
    cart.set_start_date(Date.yesterday)
    cart.start_date.should == Date.yesterday
    Reservation.validate_set(admin, cart.items).should == ["Reservations cannot be made in the past"]
  end
end
