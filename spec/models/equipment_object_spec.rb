require 'spec_helper'

describe EquipmentObject, focus: true do
  before(:each) do
    @camera_1 = FactoryGirl.build(:equipment_object)
  end
  it "has a working factory" do
    @camera_1.save.should be_true
  end
  it "must have a name" do
    @camera_1.name = ""
    @camera_1.save.should be_false
    @camera_1.name = "Number FGH4567"
    @camera_1.save.should be_true
  end
  it "must have a serial number" do
    @camera_1.serial = ""
    @camera_1.save.should be_false
    @camera_1.serial = "FGH4567"
    @camera_1.save.should be_true
  end
  it "must have an equipment model id with which it is associated" do
    @camera_1.equipment_model_id = nil
    @camera_1.save.should be_false
    @camera_1.equipment_model_id = 1
    @camera_1.save.should be_true
  end

  describe ".active" do
    it "returns all active equipment objects"
    it "does not return deactivated equipment objects"
  end
  describe ".status" do
    it "returns 'deactivated' if the object has a value for deleted_at"
    it "returns 'available' if the object is active and not currently checked out"
    # "checked out by #{r.reserver.name} through #{r.due_date.strftime("%b %d")}"
    it "returns the reservation that it is currently associated with if it is active and checked out"
  end
  describe ".current_reservation" do
    it "returns nil if the equipment object does not have an associted reservation"
    it "returns the reservation object currently holding this equipment_object if there is one that does"
  end
  describe ".available?" do
    it "returns true if the equipment object is not checked out"
    it "returns false if the equipment object is currently checked out"
  end
end
