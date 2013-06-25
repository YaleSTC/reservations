require 'spec_helper'

describe CartReservation do
	let!(:cart_reservation) { FactoryGirl.create(:reservation) }
	subject { cart_reservation }
	
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
		end
		it 'can be updated' do
			cart_reservation.due_date = Date.tomorrow + 1
			cart_reservation.save.should be_true
		end
		it 'passes custom validations' do
			cart_reservation.should be_not_empty
			cart_reservation.should be_not_in_past
			Reservation.validate_set(cart_reservation.reserver)
		end
	end
end
