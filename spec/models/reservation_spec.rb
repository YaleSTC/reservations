require 'spec_helper'

describe Reservation do
	admin = User.new(login: "netid", first_name: "First", last_name: "Last", phone: "1234567890", email: "first.last@yale.edu", affiliation: "YC", adminmode: true, terms_of_service_accepted: true)
	User.save!
	#admin = FactoryGirl.create(:admin)
	it "can run a test"

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