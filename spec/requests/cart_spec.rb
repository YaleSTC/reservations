require 'spec_helper'

describe 'cart' do

  admin = FactoryGirl.create(:admin)
  cart = Cart.new
  cart.set_reserver_id(admin.id)
  eq = FactoryGirl.create(:equipment_model)
  cart.add_item(eq)
  res = cart.items.first

  it 'initializes' do
    cart.start_date
    cart.due_date
    cart.reserver
  end

  it 'add_item works' do
    cart.items.size.should == 1
  end

  it 'remove_item works' do
    cart.remove_item(eq)
    cart.items.size.should == 0
  end

  it 'remove_item removes only one item' do
    cart.add_item(eq)
    cart.add_item(eq)
    cart.items.size.should == 2
    cart.remove_item(eq)
    cart.items.size.should == 1
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

  it 'duration_allowed? works when called on reservations in @items' do
    res.duration_allowed?.should == true
    allowed_duration = eq.category.max_checkout_length
    cart.set_due_date(Date.tomorrow + allowed_duration)
    cart.add_item(eq)
    res1 = cart.items.last
    res1.duration_allowed?.should == false
  end

  # only tests true. need to test with user with overdue reservations
  it 'no_overdue_reservations? works when called on reservations in @items' do
    res.no_overdue_reservations? == true
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

  # only tests one reservations, not an array
  it 'available? works when called on reservations in @items' do
    res.available?.should == false
    obj = FactoryGirl.create(:equipment_object, equipment_model: eq)
    res.available?.should == true
  end

  it 'valid? works when called reservations in @items' do
    cart.add_item(eq)
    res = cart.items.first
    res.valid?.should == true
  end
end
