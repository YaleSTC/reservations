require 'spec_helper'

describe EquipmentObject, :type => :model do
  context "validations" do
    before(:each) do
      @object = FactoryGirl.build(:equipment_object)
    end

    it "has a working factory" do
      expect(@object.save).to be_truthy
    end

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:equipment_model) }

    # this test passes even without the nilify_blanks call in the model, maybe delete the call?
    it "saves an empty string value as nil for deleted_at field" do
      @object.deleted_at = "   "
      @object.save
      expect(@object.deleted_at).to eq(nil)
    end
  end

  describe ".active" do
    before(:each) do
      @active = FactoryGirl.create(:equipment_object)
      @deactivated = FactoryGirl.create(:deactivated)
    end

    it "Should return all active equipment objects" do
      expect(EquipmentObject.active).to include(@active)
    end

    it "Should not return inactive equipment objects" do
      expect(EquipmentObject.active).not_to include(@deactivated)
    end
  end

  describe ".status" do
    it "returns 'Deactivated' if the object has a value for deleted_at" do
      @object = FactoryGirl.create(:equipment_object, deleted_at: Date.current)
      expect(@object.status).to eq('Deactivated')
    end
    it "returns 'available' if the object is active and not currently checked out" do
      @object = FactoryGirl.create(:equipment_object)
      expect(@object.status).to eq('available')
      @reservation = FactoryGirl.create(:valid_reservation)
      @reserved_object = EquipmentObject.find_by_equipment_model_id(@reservation.equipment_model.id)
      expect(@reserved_object.status).to eq('available')
    end
    it "returns a description of the reservation that it is currently associated with if it is active and checked out" do
      @reservation = FactoryGirl.create(:checked_out_reservation)
      @checked_out_object = @reservation.equipment_object
      expect(@checked_out_object.status).to eq("checked out by #{@reservation.reserver.name} through #{@reservation.due_date.strftime("%b %d")}")
    end
  end

  describe ".current_reservation" do
    it "returns nil if the equipment object does not have an associted reservation" do
      @object = FactoryGirl.create(:equipment_object)
      expect(@object.current_reservation).to be_nil
    end
    it "returns the reservation object currently holding this equipment_object if there is one that does" do
      @reservation = FactoryGirl.create(:checked_out_reservation)
      @reserved_object = @reservation.equipment_object
      expect(@reserved_object.current_reservation).to eq(@reservation)
    end
  end

  describe ".available?" do
    it "returns true if the equipment object is not checked out" do
      @object = FactoryGirl.create(:equipment_object)
      expect(@object.available?).to be_truthy
    end
    it "returns false if the equipment object is currently checked out" do
      @reservation = FactoryGirl.create(:checked_out_reservation)
      @checked_out_object = @reservation.equipment_object
      expect(@checked_out_object.available?).to be_falsey
    end
  end
end
