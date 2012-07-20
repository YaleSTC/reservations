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

  it 'initializes' do
    cart.start_date
    cart.due_date
    cart.reserver
  end

  it 'add_item works' do
    cart.add_item(eq)
    cart.items.size.should == 1
    CartReservation.all.size.should == 1
    CartReservation.find(cart.items.first).equipment_model.should == eq
    cart.add_item(eq)
    cart.items.size.should == 2
    CartReservation.all.size.should == 2
    cart.items.first.should_not == cart.items.last
    CartReservation.find(cart.items.last).equipment_model.should == eq
  end

  it 'remove_item works' do
    cart.items.clear
    cart.add_item(eq)
    cart.add_item(eq)
    cart.items.size.should == 2
    CartReservation.all.size.should == 2
    cart.remove_item(eq)
    cart.items.size.should == 1
    CartReservation.all.size.should == 1
  end

  it 'cart_reservations works' do
    cart.items.clear
    cart.add_item(eq)
    cartreses = []
    cartreses << CartReservation.find(cart.items.first)
    cart.cart_reservations.should == cartreses
    cart.add_item(eq)
    cartreses << CartReservation.find(cart.items.last)
    cart.cart_reservations.should == cartreses
  end

  it 'not_empty? keeps cartres from saving without equipment model' do
    cart.items.clear
    cart.add_item(eq)
    cartres = CartReservation.find(cart.items.first)
    cartres.equipment_model = nil
    cartres.not_empty?.should == false
    cartres.save.should == false
    cartres.equipment_model = eq
    cartres.not_empty?.should == true
    cartres.save.should == true
  end

  it 'not_in_past? works when called on reservations in @items' do
    cart.items.clear
    cart.add_item(eq)
    cartres = CartReservation.find(cart.items.first)
    cartres.due_date = Date.yesterday
    cartres.not_in_past?.should == false
    cartres.save.should == false
    cartres.due_date = Date.today
    cartres.not_in_past?.should == true
    cartres.save.should == true
    cartres.start_date = Date.yesterday
    cartres.not_in_past?.should == false
    cartres.save.should == false
    cartres.start_date = Date.today
    cartres.not_in_past?.should == true
    cartres.save.should == true
  end

  it 'start_date_before_due_date? works when called on reservations in @items' do
    cart.items.clear
    cart.add_item(eq)
    cartres = CartReservation.find(cart.items.first)
    cartres.due_date = Date.yesterday
    cartres.start_date_before_due_date?.should == false
    cartres.due_date = Date.today
    cartres.start_date_before_due_date?.should == true
  end

  #fix this test
#  it 'not_renewable? works when called on reservations in @items' do
#    cart.items.clear
#    cart.add_item(eq)
#    cartres = CartReservation.find(cart.items.first)
#    cartres.not_renewable?.should == true
#    renew = FactoryGirl.create(:checked_out_reservation, reserver: admin)
#    cartres.not_renewable?.should == false
#  end

  it 'no_overdue_reservations? works when called on reservations in @items' do
    cart.items.clear
    cart.add_item(eq)
    cartres = CartReservation.find(cart.items.first)
    cartres.no_overdue_reservations?.should == true
    overdue = FactoryGirl.create(:overdue_reservation, reserver: admin)
    cartres.no_overdue_reservations?.should == false
  end

  it 'duration_allowed? works when called on reservations in @items' do
    cart.items.clear
    cart.add_item(eq)
    cartres = CartReservation.find(cart.items.first)
    cartres.duration_allowed?.should == true
    allowed_duration = eq.category.max_checkout_length
    cart.set_due_date(Date.tomorrow + allowed_duration)
    cart.add_item(eq)
    bad_cartres = CartReservation.find(cart.items.last)
    bad_cartres.duration_allowed?.should == false
  end

  it 'count works when called on reservations in @items' do
    cart.items.clear
    cart.add_item(eq)
    cart.add_item(eq)
    cartres = CartReservation.find(cart.items.first)
    cartres.count(cart.cart_reservations).should == 2
    eq2 = FactoryGirl.create(:equipment_model)
    cart.add_item(eq2)
    cartres2 = CartReservation.find(cart.cart_reservations)
    cartres2.count(cart.items).should == 1
  end

  it 'available? works when called on reservations in @items' do
    cart.items.clear
    cart.add_item(eq)
    cartres = CartReservation.find(cart.items.first)
    cartres.available?.should == false
    obj = FactoryGirl.create(:equipment_object, equipment_model: eq)
    binding.pry
    cartres.available?.should == true
    cart.add_item(eq)
    cartres.available?.should == true can only see 1 without cart.items
    cart.available?(cart.items).should == false
  end

#  it 'quantity_eq_model_allowed?" works when called on reservations in @items' do
#    eq_max = FactoryGirl.create(:equipment_model, max_per_user: 1)
#    cart.add_item(eq_max)
#    res_max = cart.items.last
#    res_max.quantity_eq_model_allowed?.should == true
#    res_max.quantity_eq_model_allowed?(cart.items).should == true
#    cart.add_item(eq_max)
#    res_max.quantity_eq_model_allowed?.should == true #without cart.items it can only see 1
#    res_max.quantity_eq_model_allowed?(cart.items).should == false
#  end

#  it 'quantity_cat_allowed? works when called on reservations in @items' do
#    cat_max = FactoryGirl.create(:category, max_per_user: 1)
#    eq_cat_max = FactoryGirl.create(:equipment_model, category: cat_max)
#    cart.add_item(eq_cat_max)
#    res_cat_max = cart.items.last
#    res_cat_max.quantity_cat_allowed?.should == true
#    res_cat_max.quantity_cat_allowed?(cart.items).should == true
#    cart.add_item(eq_cat_max)
#    res_cat_max.quantity_cat_allowed?.should == true #doesn't know about cart.items
#    res_cat_max.quantity_cat_allowed?(cart.items).should == false
#  end

#  it 'changing reserver_id changes the reserver for the cart items' do
#    user = FactoryGirl.create(:user)
#    cart.set_reserver_id(user.id)
#    res = cart.items.first
#    res.reserver_id.should == user.id
#    res.reserver.should == user
#    cart.set_reserver_id(admin.id)
#    res.reserver.should == admin
#  end

#  it 'changing dates changes the reservation dates' do
#    cart.set_start_date(Date.tomorrow)
#    cart.set_due_date(Date.tomorrow + 1)
#    cart.start_date.should == Date.tomorrow
#    cart.due_date.should == Date.tomorrow + 1
#    res = cart.items.first
#    res.start_date.to_date.should == Date.tomorrow
#    res.due_date.to_date.should == Date.tomorrow + 1
#  end

#  #TODO: could write more tests for failure... probs not necessary
#  it 'valid? works when called reservations in @items' do
#    cart.items.clear
#    cart.set_start_date(Date.today)
#    cart.set_due_date(Date.tomorrow)
#    obj = FactoryGirl.create(:equipment_object)
#    eq_valid = obj.equipment_model
#    cart.add_item(eq_valid)
#    res = cart.items.first
#    res.valid?.should == true
#    r = Reservation.new(reserver: admin, start_date: Date.tomorrow, due_date: Date.yesterday)
#    r.equipment_model = eq
#    r.start_date_before_due_date?.should == false
#    r.not_in_past?.should == false
#    r.valid?.should == false
#  end

#  #TODO: write tests for all the errors (?)
#  it 'validate_set works when called on reservations in @items' do
#    cart.items.clear
#    Reservation.validate_set(admin, cart.items).should == []
#    cart.set_start_date(Date.today)
#    cart.set_due_date(Date.tomorrow)
#    obj = FactoryGirl.create(:equipment_object)
#    eq_valid = obj.equipment_model
#    cart.add_item(eq_valid)
#    Reservation.validate_set(admin, cart.items).should == []
#    cart.set_start_date(Date.yesterday)
#    cart.start_date.should == Date.yesterday
#    Reservation.validate_set(admin, cart.items).should == ["Reservations cannot be made in the past"]
#  end
end
