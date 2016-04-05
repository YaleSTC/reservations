require 'spec_helper'
require 'concerns/linkable_spec.rb'

describe EquipmentItem, type: :model do
  context 'validations' do
    before(:each) do
      @item = FactoryGirl.build(:equipment_item)
    end

    it 'has a working factory' do
      expect(@item.save).to be_truthy
    end

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:equipment_model) }

    # 2015-11-09: we can't use the shoulda matchers test for scoped uniqueness
    # due to the lack of a default value for notes - we could potentially
    # rework our database schema to add a default value but it seems
    # unnecessary at the moment
    it 'ensures unique serials scoped to equipment model if it exists' do
      em1 = FactoryGirl.create(:equipment_model)
      em2 = FactoryGirl.create(:equipment_model)
      FactoryGirl.create(:equipment_item, equipment_model: em1, serial: 'a')
      em1_a2 = FactoryGirl.build(:equipment_item, equipment_model: em1,
                                                  serial: 'a')
      em1_nil1 = FactoryGirl.build(:equipment_item, equipment_model: em1,
                                                    serial: nil)
      em1_nil2 = FactoryGirl.build(:equipment_item, equipment_model: em1,
                                                    serial: nil)
      em1_blank1 = FactoryGirl.build(:equipment_item, equipment_model: em1,
                                                      serial: '')
      em1_blank2 = FactoryGirl.build(:equipment_item, equipment_model: em1,
                                                      serial: '')
      em2_a = FactoryGirl.build(:equipment_item, equipment_model: em2,
                                                 serial: 'a')

      expect(em1_a2.valid?).to be_falsey
      expect(em1_nil1.save!).to be_truthy
      expect(em1_nil2.valid?).to be_truthy
      expect(em1_blank1.save!).to be_truthy
      expect(em1_blank2.valid?).to be_truthy
      expect(em2_a.valid?).to be_truthy
    end

    # this test passes even without the nilify_blanks call in the model, maybe
    # delete the call?
    it 'saves an empty string value as nil for deleted_at field' do
      @item.deleted_at = '   '
      @item.save
      expect(@item.deleted_at).to eq(nil)
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
    it "returns 'Deactivated' if the item has a value for deleted_at" do
      @item = FactoryGirl.create(:equipment_item,
                                 deleted_at: Time.zone.today)
      expect(@item.status).to eq('Deactivated')
    end
    it "returns 'available' if the item is active and not currently "\
      'checked out' do
      @item = FactoryGirl.create(:equipment_item)
      expect(@item.status).to eq('available')
      @reservation = FactoryGirl.create(:valid_reservation)
      @reserved_item =
        EquipmentItem
        .find_by_equipment_model_id(@reservation.equipment_model.id)
      expect(@reserved_item.status).to eq('available')
    end
    it 'returns a description of the reservation that it is currently '\
      'associated with if it is active and checked out' do
      @reservation = FactoryGirl.create(:checked_out_reservation)
      @checked_out_item = @reservation.equipment_item
      expect(@checked_out_item.status).to\
        eq("checked out by #{@reservation.reserver.name} through "\
          "#{@reservation.due_date.strftime('%b %d')}")
    end
  end

  describe '.current_reservation' do
    it 'returns nil if the equipment item does not have an associated '\
      'reservation' do
      @item = FactoryGirl.create(:equipment_item)
      expect(@item.current_reservation).to be_nil
    end
    it 'returns the reservation item currently holding this '\
      'equipment_item if there is one that does' do
      @reservation = FactoryGirl.create(:checked_out_reservation)
      @reserved_item = @reservation.equipment_item
      expect(@reserved_item.current_reservation).to eq(@reservation)
    end
  end

  describe '.available?' do
    it 'returns true if the equipment item is not checked out' do
      @item = FactoryGirl.create(:equipment_item)
      expect(@item.available?).to be_truthy
    end
    it 'returns false if the equipment item is currently checked out' do
      @reservation = FactoryGirl.create(:checked_out_reservation)
      @checked_out_item = @reservation.equipment_item
      expect(@checked_out_item.available?).to be_falsey
    end
  end

  describe '#deactivate' do
    before do
      @ei = FactoryGirl.build(:equipment_item)
      @user = FactoryGirl.build(:admin)
    end

    context 'with user and notes' do
      before { @ei.deactivate(user: @user, reason: 'reason') }

      it 'prepends to the notes' do
        expect(@ei.notes).to include('reason')
        expect(@ei.notes).to include(@user.md_link)
      end
      it 'sets deleted_at' do
        expect(@ei.deleted_at).not_to be_nil
      end
    end

    context 'without user' do
      it 'does nothing' do
        expect { @ei.deactivate(reason: 'reason') }.not_to change { @ei }
      end
    end

    context 'without notes' do
      it 'does nothing' do
        expect { @ei.deactivate(user: @user) }.not_to change { @ei }
      end
    end

    context 'without parameters' do
      it 'does nothing' do
        expect { @ei.deactivate }.not_to change { @ei }
      end
    end
  end

  it_behaves_like 'linkable'
end
