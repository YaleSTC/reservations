require 'spec_helper'

describe EquipmentItem, type: :model do
  context 'validations' do
    before(:each) do
      @object = FactoryGirl.build(:equipment_item)
    end

    it 'has a working factory' do
      expect(@object.save).to be_truthy
    end

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:equipment_model) }

    # this test passes even without the nilify_blanks call in the model, maybe
    # delete the call?
    it 'saves an empty string value as nil for deleted_at field' do
      @object.deleted_at = '   '
      @object.save
      expect(@object.deleted_at).to eq(nil)
    end
  end

  describe '.active' do
    before(:each) do
      @active = FactoryGirl.create(:equipment_item)
      @deactivated = FactoryGirl.create(:deactivated)
    end

    it 'Should return all active equipment items' do
      expect(EquipmentItem.active).to include(@active)
    end

    it 'Should not return inactive equipment items' do
      expect(EquipmentItem.active).not_to include(@deactivated)
    end
  end

  describe '.status' do
    it "returns 'Deactivated' if the object has a value for deleted_at" do
      @object = FactoryGirl.create(:equipment_item,
                                   deleted_at: Time.zone.today)
      expect(@object.status).to eq('Deactivated')
    end
    it "returns 'available' if the object is active and not currently "\
      'checked out' do
      @object = FactoryGirl.create(:equipment_item)
      expect(@object.status).to eq('available')
      @reservation = FactoryGirl.create(:valid_reservation)
      @reserved_object =
        EquipmentItem
        .find_by_equipment_model_id(@reservation.equipment_model.id)
      expect(@reserved_object.status).to eq('available')
    end
    it 'returns a description of the reservation that it is currently '\
      'associated with if it is active and checked out' do
      @reservation = FactoryGirl.create(:checked_out_reservation)
      @checked_out_object = @reservation.equipment_item
      expect(@checked_out_object.status).to\
        eq("checked out by #{@reservation.reserver.name} through "\
          "#{@reservation.due_date.strftime('%b %d')}")
    end
  end

  describe '.current_reservation' do
    it 'returns nil if the equipment item does not have an associated '\
      'reservation' do
      @object = FactoryGirl.create(:equipment_item)
      expect(@object.current_reservation).to be_nil
    end
    it 'returns the reservation object currently holding this '\
      'equipment_item if there is one that does' do
      @reservation = FactoryGirl.create(:checked_out_reservation)
      @reserved_object = @reservation.equipment_item
      expect(@reserved_object.current_reservation).to eq(@reservation)
    end
  end

  describe '.available?' do
    it 'returns true if the equipment item is not checked out' do
      @object = FactoryGirl.create(:equipment_item)
      expect(@object.available?).to be_truthy
    end
    it 'returns false if the equipment item is currently checked out' do
      @reservation = FactoryGirl.create(:checked_out_reservation)
      @checked_out_object = @reservation.equipment_item
      expect(@checked_out_object.available?).to be_falsey
    end
  end
end
