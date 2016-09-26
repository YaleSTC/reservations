# frozen_string_literal: true
require 'spec_helper'
require 'concerns/linkable_spec.rb'

describe EquipmentItem, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  it_behaves_like 'linkable'

  describe 'basic validations' do
    subject(:item) { FactoryGirl.build(:equipment_item) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:equipment_model) }
  end

  describe 'serial' do
    it 'can be blank' do
      item = FactoryGirl.build_stubbed(:equipment_item, serial: '')
      expect(item.valid?).to be_truthy
    end
    it 'can be nil' do
      item = FactoryGirl.build_stubbed(:equipment_item, serial: nil)
      expect(item.valid?).to be_truthy
    end
    it 'cannot be the same as another item of the same model' do
      model = FactoryGirl.create(:equipment_model)
      FactoryGirl.create(:equipment_item, equipment_model: model, serial: 'a')
      item = FactoryGirl.build(:equipment_item, equipment_model: model,
                                                serial: 'a')
      expect(item.valid?).to be_falsey
    end
    it 'can be the same as another item of a different model' do
      FactoryGirl.create(:equipment_item,
                         serial: 'a',
                         equipment_model: FactoryGirl.create(:equipment_model))
      item =
        FactoryGirl.build(:equipment_item,
                          serial: 'a',
                          equipment_model: FactoryGirl.create(:equipment_model))
      expect(item.valid?).to be_truthy
    end
  end

  it 'saves an empty string value as nil for deleted_at field' do
    # this test passes even without the nilify_blanks call in the model, maybe
    # delete the call?
    item = FactoryGirl.build(:equipment_item)
    item.deleted_at = '   '
    item.save
    expect(item.deleted_at).to eq(nil)
  end

  describe '#active' do
    it 'returns active equipment items' do
      active = FactoryGirl.create(:equipment_item)
      FactoryGirl.create(:deactivated_item)
      expect(described_class.active).to match_array([active])
    end
  end

  describe '#for_eq_model' do
    it 'counts the number of items for the given model' do
      items = Array.new(2) { |i| EquipmentItemMock.new(equipment_model_id: i) }
      expect(described_class.for_eq_model(0, items)).to eq(1)
    end
  end

  describe '#status' do
    it "returns 'Deactivated' when deleted_at is set" do
      item = FactoryGirl.build_stubbed(:equipment_item,
                                       deleted_at: Time.zone.today)
      expect(item.status).to eq('Deactivated')
    end
    it "returns 'available' when active and not currently checked out" do
      item = FactoryGirl.build_stubbed(:equipment_item)
      expect(item.status).to eq('available')
    end
    it 'includes reservation information when checked out' do
      res = FactoryGirl.create(:checked_out_reservation)
      item = res.equipment_item
      expect(item.status).to include('checked out by')
    end
    it 'includes deactivation reason if it is set' do
      reason = 'because i can'
      item = FactoryGirl.build_stubbed(:equipment_item,
                                       deleted_at: Time.zone.today,
                                       deactivation_reason: reason)
      expect(item.status).to include(reason)
    end
  end

  describe '#current_reservation' do
    it 'returns nil if no associated reservation' do
      item = FactoryGirl.build_stubbed(:equipment_item)
      expect(item.current_reservation).to be_nil
    end
    it 'returns the reservation that currently has the item checked out' do
      res = FactoryGirl.create(:checked_out_reservation)
      item = res.equipment_item
      expect(item.current_reservation).to eq(res)
    end
  end

  describe '#available?' do
    it 'returns true when the status is available' do
      item = FactoryGirl.build_stubbed(:equipment_item)
      expect(item.available?).to be_truthy
    end
    it 'returns false if when the status is not available' do
      item = FactoryGirl.build_stubbed(:equipment_item)
      allow(item).to receive(:status).and_return('not')
      expect(item.available?).to be_falsey
    end
  end

  describe '#make_reservation_notes' do
    let!(:user) { UserMock.new(md_link: 'md_link') }
    let!(:item) { FactoryGirl.build(:equipment_item) }
    it 'updates the notes' do
      allow(item).to receive(:update_attributes)
      item.make_reservation_notes('', ReservationMock.new(reserver: user), user,
                                  '', Time.zone.now)
      expect(item).to have_received(:update_attributes)
        .with(hash_including(:notes))
    end
    it 'includes the given time' do
      time = Time.zone.now
      item.make_reservation_notes('', ReservationMock.new(reserver: user), user,
                                  '', time)
      expect(item.notes).to include(time.to_s(:long))
    end
    it 'includes the current user link' do
      item.make_reservation_notes('',
                                  ReservationMock.new(reserver: UserMock.new),
                                  user, '', Time.zone.now)
      expect(item.notes).to include(user.md_link)
    end
    it 'includes the reservation link' do
      res = ReservationMock.new(reserver: UserMock.new, md_link: 'res_link')
      item.make_reservation_notes('', res, user, '', Time.zone.now)
      expect(item.notes).to include(res.md_link)
    end
    it 'includes the reserver link' do
      reserver = UserMock.new(md_link: 'reserver_link')
      res = ReservationMock.new(reserver: reserver)
      item.make_reservation_notes('', res, user, '', Time.zone.now)
      expect(item.notes).to include(reserver.md_link)
    end
    it 'includes extra notes' do
      item.make_reservation_notes('',
                                  ReservationMock.new(reserver: UserMock.new),
                                  user, 'extra_note', Time.zone.now)
      expect(item.notes).to include('extra_note')
    end
  end

  describe '#make_switch_notes' do
    let!(:user) { UserMock.new }
    let!(:item) { FactoryGirl.build(:equipment_item) }
    it 'updates the notes' do
      allow(item).to receive(:update_attributes)
      item.make_switch_notes(nil, nil, user)
      expect(item).to have_received(:update_attributes)
        .with(hash_including(:notes))
    end
    it 'includes the reservation links when passed' do
      old = ReservationMock.new(md_link: 'old_link')
      new = ReservationMock.new(md_link: 'new_link')
      item.make_switch_notes(old, new, user)
      expect(item.notes).to include(old.md_link)
      expect(item.notes).to include(new.md_link)
    end
    it 'includes the current time' do
      travel(-1.days) do
        time = Time.zone.now.to_s(:long)
        item.make_switch_notes(nil, nil, user)
        expect(item.notes).to include(time)
      end
    end
    it 'includes the handler link' do
      allow(user).to receive(:md_link).and_return('user_link')
      item.make_switch_notes(nil, nil, user)
      expect(item.notes).to include(user.md_link)
    end
  end

  describe '#update' do
    let!(:user) { UserMock.new }
    context 'no changes' do
      let!(:item) { FactoryGirl.build_stubbed(:equipment_item) }
      it 'does nothing' do
        expect { item.update(user, {}) }.not_to change { item.notes }
      end
    end
    context 'any changes' do
      let!(:item) { FactoryGirl.build_stubbed(:equipment_item) }
      it 'includes the current time' do
        travel(-1.days) do
          time = Time.zone.now.to_s(:long)
          item.update(user, serial: 'a')
          expect(item.notes).to include(time)
        end
      end
      it 'includes the current user' do
        allow(user).to receive(:md_link).and_return('user_link')
        item.update(user, serial: 'a')
        expect(item.notes).to include(user.md_link)
      end
    end
    shared_examples 'string change noted' do |attr|
      it do
        old_value = 'a'
        new_value = 'b'
        item = FactoryGirl.build_stubbed(:equipment_item, attr => old_value)
        item.update(user, attr => new_value)
        expect(item.notes).to include(old_value)
        expect(item.notes).to include(new_value)
      end
    end
    it_behaves_like 'string change noted', :name
    it_behaves_like 'string change noted', :serial
    context 'changing the equipment model' do
      it 'notes the change' do
        old_model = FactoryGirl.create(:equipment_model)
        new_model = FactoryGirl.create(:equipment_model)
        item = FactoryGirl.build_stubbed(:equipment_item,
                                         equipment_model: old_model)
        item.update(user, equipment_model_id: new_model.id)
        expect(item.notes).to include('Equipment Model')
        expect(item.notes).to include(old_model.name)
        expect(item.notes).to include(new_model.name)
      end
    end
  end

  describe '#deactivate' do
    let!(:user) { UserMock.new(md_link: 'md_link') }
    let!(:item) { FactoryGirl.build_stubbed(:equipment_item) }
    before do
      allow(item).to receive(:destroy)
      allow(item).to receive(:save!)
    end
    context 'with user and notes' do
      it 'saves the updated attributes' do
        item.deactivate(user: user, reason: 'reason')
        expect(item).to have_received(:save!)
      end
      it 'destroys the item' do
        item.deactivate(user: user, reason: 'reason')
        expect(item).to have_received(:destroy)
      end
      it 'prepends to the notes' do
        item.deactivate(user: user, reason: 'reason')
        expect(item.notes).to include('reason')
        expect(item.notes).to include(user.md_link)
      end
    end
    context 'without user' do
      it 'does nothing' do
        expect { item.deactivate(reason: 'reason') }.not_to change { item }
      end
    end
    context 'without notes' do
      it 'does nothing' do
        expect { item.deactivate(user: user) }.not_to change { item }
      end
    end
    context 'without parameters' do
      it 'does nothing' do
        expect { item.deactivate }.not_to change { item }
      end
    end
  end
end
