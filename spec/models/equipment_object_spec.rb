require 'spec_helper'

describe EquipmentObject do
  context "validations" do
    before(:each) do
      @object = FactoryGirl.build(:equipment_object)
    end

    it "has a working factory" do
      @object.save.should be_true
    end

    it "must have a name" do
      @object.name = ""
      @object.save.should be_false
      @object.name = "Number FGH4567"
      @object.save.should be_true
    end

    it "must have an equipment model with which it is associated" do
      @model = @object.equipment_model
      @object.equipment_model = nil
      @object.save.should be_false
      @object.equipment_model = @model
      @object.save.should be_true
    end
    # this test passes even without the nilify_blanks call in the model, maybe delete the call?
    it "saves an empty string value as nil for deleted_at field" do
      @object.deleted_at = "   "
      @object.save
      @object.deleted_at.should == nil
    end
  end

  describe ".active" do
    before(:each) do
      @active = FactoryGirl.create(:equipment_object)
      @deactivated = FactoryGirl.create(:deactivated)
    end

    it "Should return all active equipment objects" do
      EquipmentObject.active.should include(@active)
    end

    it "Should not return inactive equipment objects" do
      EquipmentObject.active.should_not include(@deactivated)
    end
  end

  # wait to do these until this is merged with the reservations tests/factories

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
