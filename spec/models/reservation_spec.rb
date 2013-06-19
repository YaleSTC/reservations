require 'spec_helper'

describe Reservation do
	admin = FactoryGirl.create(:admin)
	user = FactoryGirl.create(:user)
	model = FactoryGirl.create(:equipment_model)
	object = FactoryGirl.create(:equipment_object, equipment_model: model)

	reservation = Reservation.new(reserver: user, equipment_object: object, 
		start_date: Date.today, due_date: Date.tomorrow)
	reservation.equipment_model = model

	it "can be created" do
		reservation.save.should be_true
		Reservation.all.size.should be == 1
		binding.pry
	end
	it "can be updated" do
		reservation.start_date = Date.tomorrow
		reservation.save.should be_true
	end
	it "does not save when invalid" do
		invalid = Reservation.new(reserver: user, start_date: Date.today, due_date: Date.tomorrow)
		invalid.should_not be_not_empty
		invalid.save.should be_false
		Reservation.all.size.should be == 1
	end
	it "fails when reserver has overdue reservations" do
		overdue = FactoryGirl.build(:overdue_reservation, reserver: user)
		overdue.save(:validate => false)
		binding.pry
		reservation.no_overdue_reservations?.should be_false
		reservation.save.should be_false
	end
	it "fails when dates are impossible"
	it "fails when no equipment model is specified"
	it "fails when the equipment object does not match the equipment model"
	it "fails when the duration is too long"
	it "fails when start/due dates are blacked out"
	it "fails when the object isn't available for the entire reservation"
	it "fails when reserver has too many of the equipment model or category out"
	it "fails to renew when the object is not renewable"

	User.delete_all
	EquipmentObject.delete_all
	EquipmentModel.delete_all
	Reservation.delete_all
end