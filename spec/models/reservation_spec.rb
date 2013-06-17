require 'spec_helper'

describe Reservation do
	before(:all) do
		binding.pry
		admin = FactoryGirl.create(:admin)
		user = FactoryGirl.create(:user)
		object = FactoryGirl.create(:equipment_object)
		model = object.equipment_model
	end

	after(:all) do
		User.delete_all
		EquipmentObject.delete_all
		EquipmentModel.delete_all
		Reservation.delete_all
	end

	it "can be created"
	it "can be updated"
	it "passes validations when valid"
	it "saves when valid"
	it "does not save when invalid"
	it "fails when reserver has overdue reservations"
	it "fails when dates are impossible"
	it "fails when no equipment model is specified"
	it "fails when the equipment object does not match the equipment model"
	it "fails when the duration is too long"
	it "fails when start/due dates are blacked out"
	it "fails when the object isn't available for the entire reservation"
	it "fails when reserver has too many of the equipment model or category out"
	it "fails to renew when the object is not renewable"
end