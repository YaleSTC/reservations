require 'spec_helper'

describe CartReservation do
	
	context "when valid" do
		let(:cart_reservation) { FactoryGirl.build(:cart_reservation) }
		subject { cart_reservation }
		
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
		end
		it 'can be updated' do
			cart_reservation.due_date = Date.tomorrow + 1
			cart_reservation.save.should be_true
		end
		it 'passes custom validations' do
			cart_reservation.should be_not_empty
			cart_reservation.should be_not_in_past
			Reservation.validate_set(cart_reservation.reserver).should == []
		end
	end

	context "when empty" do
		let(:cart_reservation) { FactoryGirl.build(:cart_reservation, equipment_model: nil) }
		subject { cart_reservation }

		it { should_not be_valid }
		its(:equipment_model) { should be_nil }
		it 'should not save' do
			cart_reservation.save.should be_false
		end
		it 'cannot be updated' do
			cart_reservation.due_date = Date.tomorrow + 1
			cart_reservation.save.should be_false
		end
		it 'fails custom validations appropriately' do
			cart_reservation.should_not be_not_empty
			cart_reservation.should be_not_in_past
			#Reservation.validate_set(cart_reservation.reserver, [] << cart_reservation).should_not == []
		end
		it 'can be updated with equipment model' do
			cart_reservation.equipment_model = FactoryGirl.create(:equipment_model)
			cart_reservation.save.should be_true
		end
	end

end