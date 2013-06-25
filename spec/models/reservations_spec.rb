require 'spec_helper'

describe Reservation do
	subject(:reservation) { FactoryGirl.build(:reservation) }
	
	context "when valid" do
		it { should be_valid }
		it 'should have a valid reserver' do
			reservation.reserver.should_not be_nil
			reservation.reserver.first_name.should_not == "Deleted"
		end
		its(:equipment_model) { should_not be_nil }
		its(:start_date) { should_not be_nil }
		its(:due_date) { should_not be_nil }
		it 'should save' do
			reservation.save.should be_true
			Reservation.all.size.should == 1
			Reservation.all.first.should == reservation
		end
		it 'can be updated' do
			reservation.due_date = Date.tomorrow + 1
			reservation.save.should be_true
		end
		it 'should pass custom validations' do
			reservation.should be_no_overdue_reservations
			reservation.should be_start_date_before_due_date
			reservation.should be_not_in_past
			reservation.should be_not_empty
			reservation.should be_matched_object_and_model
			reservation.should be_duration_allowed
			reservation.should be_start_date_is_not_blackout
			reservation.should be_due_date_is_not_blackout
			reservation.should be_available
			reservation.should be_quantity_eq_model_allowed
			reservation.should be_quantity_cat_allowed
			Reservation.validate_set(reservation.reserver).should == []
		end
		context "when not checked out" do
			its(:status) { should == 'reserved' }
			#it { should_not be_is_eligible_for_renew } currently returns true; doesn't check for checked out
		end
		it { should respond_to(:fake_reserver_id) }
		it { should respond_to(:late_fee) }
		it { should respond_to(:max_renewal_length_available) }
	end


end