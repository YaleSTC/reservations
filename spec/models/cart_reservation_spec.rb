require 'spec_helper'

describe CartReservation do
  subject(:cart_reservation) { FactoryGirl.build(:cart_reservation) }

  it { should belong_to(:equipment_model) }
  it { should belong_to(:reserver) }
  it { should validate_presence_of(:reserver) }
  it { should validate_presence_of(:equipment_model) }
  it { should validate_presence_of(:start_date) }
  it { should validate_presence_of(:due_date) } 

  
  context "when valid" do
    it { should be_valid }
    it 'should have a valid reserver' do
      cart_reservation.reserver.should_not be_nil
      cart_reservation.reserver.first_name.should_not == "Deleted"
    end
    its(:equipment_model) { should_not be_nil }
    its(:start_date) { should_not be_nil }
    its(:due_date) { should_not be_nil }
    it 'should save' do
      cart_reservation.save.should be_true
      CartReservation.all.size.should == 1
      CartReservation.all.first.should == cart_reservation
    end
    it 'can be updated' do
      cart_reservation.due_date = Date.tomorrow + 1
      cart_reservation.save.should be_true
    end
    it 'passes custom validations' do
      cart_reservation.should be_not_empty
      cart_reservation.should be_not_in_past
      cart_reservation.should be_no_overdue_reservations
      cart_reservation.should be_start_date_before_due_date
      cart_reservation.should be_matched_object_and_model
      cart_reservation.should be_duration_allowed
      cart_reservation.should be_start_date_is_not_blackout
      cart_reservation.should be_due_date_is_not_blackout
      cart_reservation.should be_available
      cart_reservation.should be_quantity_eq_model_allowed
      cart_reservation.should be_quantity_cat_allowed
      Reservation.validate_set(cart_reservation.reserver, [] << cart_reservation).should == []
    end
  end

  context "when empty" do
    subject(:cart_reservation) { FactoryGirl.build(:cart_reservation, equipment_model: nil) }
    
    it { should_not be_valid }
    it 'should not save' do
      cart_reservation.save.should be_false
      CartReservation.all.size.should == 0
    end
    it 'cannot be updated' do
      cart_reservation.due_date = Date.tomorrow + 1
      cart_reservation.save.should be_false
    end
    it 'fails appropriate validations' do
      cart_reservation.should_not be_not_empty
      Reservation.validate_set(cart_reservation.reserver, [] << cart_reservation).should_not == []
    end
    it 'passes other custom validations' do
      cart_reservation.should be_not_in_past
      cart_reservation.should be_no_overdue_reservations
      cart_reservation.should be_start_date_before_due_date
      cart_reservation.should be_matched_object_and_model
      cart_reservation.should be_duration_allowed
      cart_reservation.should be_start_date_is_not_blackout
      cart_reservation.should be_due_date_is_not_blackout
      cart_reservation.should be_available
      cart_reservation.should be_quantity_eq_model_allowed
      cart_reservation.should be_quantity_cat_allowed
    end
    it 'can be updated with equipment model' do
      cart_reservation.equipment_model = FactoryGirl.create(:equipment_model)
      cart_reservation.save.should be_true
      cart_reservation.should be_valid
      CartReservation.all.size.should == 1
    end
  end

  context "with bad dates" do
    subject(:cart_reservation) { FactoryGirl.build(:cart_reservation, due_date: Date.yesterday) }

    it { should_not be_valid }
    it 'should not save' do
      cart_reservation.save.should be_false
      CartReservation.all.size.should == 0
    end
    it 'cannot be updated' do
      cart_reservation.start_date = Date.tomorrow
      cart_reservation.save.should be_false
    end
    it 'fails appropriate validations' do
      cart_reservation.should_not be_start_date_before_due_date
      cart_reservation.should_not be_not_in_past
      Reservation.validate_set(cart_reservation.reserver, [] << cart_reservation).should_not == []
    end
    it 'passes other custom validations' do
      cart_reservation.should be_no_overdue_reservations
      cart_reservation.should be_not_empty
      cart_reservation.should be_matched_object_and_model
      cart_reservation.should be_duration_allowed
      cart_reservation.should be_start_date_is_not_blackout
      cart_reservation.should be_due_date_is_not_blackout
      cart_reservation.should be_available
      cart_reservation.should be_quantity_eq_model_allowed
      cart_reservation.should be_quantity_cat_allowed
    end
    it 'can be updated with fixed date' do
      cart_reservation.due_date = Date.tomorrow
      cart_reservation.save.should be_true
      cart_reservation.should be_valid
      CartReservation.all.size.should == 1
    end
  end

end