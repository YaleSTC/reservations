require 'spec_helper'

describe 'cart and cart reservations' do
  CartReservation.delete_all
  User.delete_all
  EquipmentObject.delete_all
  EquipmentModel.delete_all
  Reservation.delete_all

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
    cart.cart_reservations.first.equipment_model.should == eq
    cart.add_item(eq)
    cart.items.size.should == 2
    CartReservation.all.size.should == 2
    cart.items.first.should_not == cart.items.last
    cart.cart_reservations.last.equipment_model.should == eq
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
    cartreses << cart.cart_reservations.first
    cart.cart_reservations.should == cartreses
    cart.add_item(eq)
    cartreses << cart.cart_reservations.last
    cart.cart_reservations.should == cartreses
  end

  it 'not_empty? keeps cartres from saving without equipment model' do
    cart.items.clear
    cart.add_item(eq)
    cartres = cart.cart_reservations.first
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
    cartres = cart.cart_reservations.first
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
    cartres = cart.cart_reservations.first
    cartres.due_date = Date.yesterday
    cartres.start_date_before_due_date?.should == false
    cartres.due_date = Date.today
    cartres.start_date_before_due_date?.should == true
  end

  it 'not_renewable? works when called on reservations in @items' do
    cart = Cart.new
    res = FactoryGirl.build(:checked_out_reservation)
    res.save
    u = User.find(res.reserver_id)
    eqres = res.equipment_model
    cart.set_reserver_id(u.id)
    cart.add_item(eqres)
    cartres = cart.cart_reservations.first
    cartres.not_renewable?.should == true
    cartres.start_date = Date.tomorrow
    cartres.not_renewable?.should == false
  end

  it 'no_overdue_reservations? works when called on reservations in @items' do
    cart = Cart.new
    cart.set_reserver_id(admin.id)
    cart.items.clear
    cart.add_item(eq)
    cartres = cart.cart_reservations.first
    cartres.no_overdue_reservations?.should == true
    overdue = FactoryGirl.build(:overdue_reservation, reserver: admin)
    overdue.save(:validate => false)
    cartres.no_overdue_reservations?.should == false
  end

  it 'duration_allowed? works when called on reservations in @items' do
    cart.items.clear
    cart.add_item(eq)
    cartres = cart.cart_reservations.first
    cartres.duration_allowed?.should == true
    allowed_duration = eq.category.maximum_checkout_length
    cart.set_due_date(Date.tomorrow + allowed_duration)
    cart.add_item(eq)
    bad_cartres = cart.cart_reservations.last
    bad_cartres.duration_allowed?.should == false
  end

  it 'same_model_count works when called on reservations in @items' do
    cart.items.clear
    cart.add_item(eq)
    cart.add_item(eq)
    cartres = cart.cart_reservations.first
    cartres.same_model_count(cart.cart_reservations).should == 2
    eq2 = FactoryGirl.create(:equipment_model)
    cart.add_item(eq2)
    cartres2 = cart.cart_reservations.last
    cartres2.same_model_count(cart.cart_reservations).should == 1
  end

  it 'available? works when called on reservations in @items' do
    cart.items.clear
    cart.add_item(eq)
    cartres = cart.cart_reservations.first
    cartres.available?.should == false
    obj = FactoryGirl.create(:equipment_object)
    mod_obj = obj.equipment_model
    cart.add_item(mod_obj)
    avail_cartres = cart.cart_reservations.last
    avail_cartres.available?.should == true
    cart.add_item(mod_obj)
    avail_cartres.available?.should == true #can only see 1 without cart.items
    avail_cartres.available?(cart.cart_reservations).should == false
  end

  it 'quantity_eq_model_allowed?" works when called on reservations in @items' do
    cart.items.clear
    eq_max = FactoryGirl.create(:equipment_model, max_per_user: 1)
    cart.add_item(eq_max)
    res_max = cart.cart_reservations.last
    res_max.quantity_eq_model_allowed?.should == true
    res_max.quantity_eq_model_allowed?(cart.cart_reservations).should == true
    cart.add_item(eq_max)
    res_max.quantity_eq_model_allowed?.should == true #without cart.items it can only see 1
    res_max.quantity_eq_model_allowed?(cart.cart_reservations).should == false
  end

  it 'quantity_cat_allowed? works when called on reservations in @items' do
    cart.items.clear
    cat_max = FactoryGirl.create(:category, max_per_user: 1)
    eq_cat_max = FactoryGirl.create(:equipment_model, category: cat_max)
    cart.add_item(eq_cat_max)
    res_cat_max = cart.cart_reservations.last
    res_cat_max.quantity_cat_allowed?.should == true
    res_cat_max.quantity_cat_allowed?(cart.cart_reservations).should == true
    cart.add_item(eq_cat_max)
    res_cat_max.quantity_cat_allowed?.should == true #doesn't know about cart.items
    res_cat_max.quantity_cat_allowed?(cart.cart_reservations).should == false
  end

  it 'changing reserver_id changes the reserver for the cart items' do
    cart.items.clear
    cart.add_item(eq)
    cartres = cart.cart_reservations.first
    cartres.reserver.should == admin
    user = FactoryGirl.create(:user)
    cart.set_reserver_id(user.id)
    cartres = cart.cart_reservations.first
    cartres.reserver_id.should == user.id
    cartres.reserver.should == user
    cart.set_reserver_id(admin.id)
    cartres = cart.cart_reservations.first
    cartres.reserver.should == admin
  end

  it 'changing dates changes the reservation dates' do
    cart = Cart.new
    cart.set_reserver_id(admin.id)
    cart.add_item(eq)
    cartres = cart.cart_reservations.first
    cartres.start_date.to_date.should == Date.today
    cartres.due_date.to_date.should == Date.tomorrow
    cart.set_start_date(Date.tomorrow)
    cart.start_date.should == Date.tomorrow
    cart.due_date.should == Date.tomorrow + 1
    cartres = cart.cart_reservations.first
    cartres.start_date.to_date.should == Date.tomorrow
    cartres.due_date.to_date.should == Date.tomorrow + 1
  end

  it 'valid? works when called reservations in @items' do
    cart.items.clear
    cart.set_start_date(Date.today)
    cart.set_due_date(Date.tomorrow)
    cart.add_item(eq)
    cartres = cart.cart_reservations.first
    cartres.valid?.should == true
    cartres.equipment_model = nil
    cartres.valid?.should == false
    cartres.equipment_model = eq
    cartres.start_date = Date.yesterday
    cartres.valid?.should == false
  end

  #TODO: write tests for all the errors (?)
  it 'validate_set works when called on reservations in @items' do
    Reservation.delete_all
    CartReservation.delete_all
    cart = Cart.new
    cart.set_reserver_id(admin.id)
    Reservation.validate_set(admin, cart.cart_reservations).should == []
    obj = FactoryGirl.create(:equipment_object)
    eq_valid = obj.equipment_model
    cart.add_item(eq_valid)
    Reservation.validate_set(admin, cart.cart_reservations).should == []
    res = FactoryGirl.build(:overdue_reservation)
    res.save(:validate => false)
    user = User.find(res.reserver_id)
    cart.set_reserver_id(user.id)
    Reservation.validate_set(user, cart.cart_reservations).should == [] << cart.reserver.name + " has overdue reservations that prevent new ones from being created"
  end
end
