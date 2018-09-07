# frozen_string_literal: true

# rubocop:disable Rails/SkipsModelValidations

require 'spec_helper'
require 'concerns/linkable_spec.rb'

describe Reservation, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  it_behaves_like 'linkable'

  describe 'counter cache' do
    context 'newly overdue reservation' do
      it 'increments when a reservation is marked as overdue' do
        res = FactoryGirl.create(:checked_out_reservation,
                                 start_date: Time.zone.today - 2.days,
                                 due_date: Time.zone.today - 1.day)
        res.update_columns(overdue: false)
        expect(res.equipment_model).to \
          receive(:increment!).with(:overdue_count).once
        res.update_attributes(overdue: true)
      end
    end
    context 'already overdue reservation' do
      it "updating other attributes doesn't affect the cache" do
        res = FactoryGirl.create(:overdue_reservation)
        expect(res.equipment_model).not_to receive(:increment!)
        res.update_attribute(:notes, 'test')
      end
      it 'decrements when checked in' do
        res = FactoryGirl.create(:overdue_reservation)
        expect(res.equipment_model).to \
          receive(:decrement!).with(:overdue_count).once
        res.update_attributes(
          FactoryGirl.attributes_for(:overdue_returned_reservation,
                                     equipment_model: res.equipment_model)
        )
      end
      it 'decrements when a reservation is extended' do
        res = FactoryGirl.create(:overdue_reservation)
        expect(res.equipment_model).to \
          receive(:decrement!).with(:overdue_count).once
        res.update_attribute(:due_date, Time.zone.today + 1.day)
      end
      it 'decrements when an overdue reservation is destroyed' do
        res = FactoryGirl.create(:overdue_reservation)
        expect(res.equipment_model).to \
          receive(:decrement!).with(:overdue_count).once
        res.destroy!
      end
    end
    context 'overdue, returned reservation' do
      it 'only decrements once per reservation' do
        res = FactoryGirl.create(:overdue_returned_reservation)
        expect(res.equipment_model).not_to receive(:decrement!)
        res.update_attribute(:notes, 'test')
      end
    end
    context 'normal checked out reservation' do
      it "doesn't change when a normal reservation is checked in" do
        res = FactoryGirl.create(:checked_out_reservation)
        expect(res.equipment_model).not_to receive(:decrement!)
        expect(res.equipment_model).not_to receive(:increment!)
        res.update_attributes(
          FactoryGirl.attributes_for(:checked_in_reservation,
                                     equipment_model: res.equipment_model)
        )
      end
    end
  end

  describe 'deletable_missed' do
    context 'when reservations are set to expire' do
      it 'collects appropriate reservations' do
        mock_app_config(res_exp_time: 2)
        old = FactoryGirl.create(:missed_reservation,
                                 start_date: Time.zone.today - 3.days,
                                 due_date: Time.zone.today - 2.days)
        FactoryGirl.create(:missed_reservation,
                           start_date: Time.zone.today - 1.day,
                           due_date: Time.zone.today)
        expect(Reservation.deletable_missed).to eq([old])
      end
    end
    context "when reservations don't expire" do
      it 'returns none' do
        mock_app_config(res_exp_time: '')
        FactoryGirl.create(:missed_reservation,
                           start_date: Time.zone.today - 3.days,
                           due_date: Time.zone.today - 2.days)
        FactoryGirl.create(:missed_reservation,
                           start_date: Time.zone.today - 2.days,
                           due_date: Time.zone.today - 1.day)
        expect(Reservation.deletable_missed).to be_empty
      end
    end
  end

  describe 'missed_not_emailed' do
    it 'collects the appropriate reservations' do
      not_emailed = FactoryGirl.create(:missed_reservation)
      FactoryGirl.create(:missed_reservation,
                         flags: Reservation::FLAGS[:missed_email_sent])
      expect(Reservation.missed_not_emailed).to eq([not_emailed])
    end
  end

  describe 'newly_missed' do
    it 'collects the appropriate reservations' do
      FactoryGirl.create(:missed_reservation)
      missed = FactoryGirl.create(:missed_reservation, status: 'reserved')
      expect(Reservation.newly_missed).to eq([missed])
    end
  end

  describe 'newly overdue' do
    it 'collects the appropriate reservations' do
      FactoryGirl.create(:overdue_reservation)
      overdue = FactoryGirl.create(:overdue_reservation)
      overdue.update_columns(overdue: false)
      expect(Reservation.newly_overdue).to eq([overdue])
    end
  end

  describe '.number_for' do
    it 'counts the number that overlap with today' do
      source = Array.new(2) { ReservationMock.new }
      source.each do |r|
        allow(r).to receive(:overlaps_with).with(Time.zone.today)
                                           .and_return(true)
      end
      expect(described_class.number_for(source)).to eq(2)
    end
    it 'counts the number that overlap with a given day' do
      date = Time.zone.today + 2.days
      source = Array.new(2) { ReservationMock.new }
      allow(source.first).to receive(:overlaps_with).with(date).and_return(true)
      allow(source.last).to receive(:overlaps_with).with(date).and_return(false)
      expect(described_class.number_for(source, date: date)).to eq(1)
    end
    it 'counts according to attribute hash' do
      attrs = { overdue: false }
      res = ReservationMock.new
      described_class.number_for([res], **attrs)
      expect(res).to have_received(:attrs?).with(**attrs)
    end
  end

  describe '.number_for_date_range' do
    it 'counts the number of reservations over a date range' do
      date_range = Time.zone.today..(Time.zone.today + 2.days)
      source = []
      date_range.each do |date|
        allow(described_class).to receive(:number_for).with(source, date: date)
      end
      described_class.number_for_date_range(source, date_range)
      date_range.each do |date|
        expect(described_class).to have_received(:number_for)
          .with(source, date: date)
      end
    end
  end

  describe '.completed_procedures' do
    it 'returns an empty array when passed nil' do
      expect(described_class.completed_procedures(nil)).to eq([])
    end
    it "collects an array of keys that have value '1'" do
      hash = { collected: '1', not_collected: '0' }
      expect(described_class.completed_procedures(hash)).to \
        eq([:collected, nil])
    end
  end

  describe '.unique_equipment_items?' do
    it 'returns false when the set has duplicate items' do
      set = Array.new(2) { ReservationMock.new(equipment_item_id: 1) }
      expect(described_class.unique_equipment_items?(set)).to be_falsey
    end
    it 'returns true when the set has no duplicate items' do
      set = Array.new(2) { |i| ReservationMock.new(equipment_item_id: i) }
      expect(described_class.unique_equipment_items?(set)).to be_truthy
    end
  end

  describe 'custom validations' do
    context 'start date after due date' do
      subject(:res) do
        FactoryGirl.build(:valid_reservation,
                          start_date: Time.zone.today + 3.days,
                          due_date: Time.zone.today)
      end
      it { is_expected.not_to be_valid }
    end
    context 'has an item of a different model' do
      subject(:res) do
        item = FactoryGirl.create(:equipment_item)
        model = FactoryGirl.create(:equipment_model)
        FactoryGirl.build(:valid_reservation, equipment_model: model,
                                              equipment_item: item)
      end
      it { is_expected.not_to be_valid }
    end
    describe 'availability validation' do
      context 'availability issues' do
        subject(:res) do
          model = FactoryGirl.create(:equipment_model)
          allow(model).to receive(:num_available).and_return(0)
          FactoryGirl.build(:valid_reservation, equipment_model: model)
        end
        it { is_expected.not_to be_valid }
      end
    end
    context 'start date is in the past' do
      subject(:res) do
        FactoryGirl.build(:valid_reservation,
                          start_date: Time.zone.today - 1.day)
      end
      it { is_expected.not_to be_valid }
    end
    context 'due date is in the past' do
      subject(:res) do
        FactoryGirl.build(:valid_reservation, due_date: Time.zone.today - 1.day)
      end
      it { is_expected.not_to be_valid }
    end
    context 'reserver is banned' do
      subject(:res) do
        user = FactoryGirl.create(:banned)
        FactoryGirl.build(:valid_reservation, reserver: user)
      end
      it { is_expected.not_to be_valid }
    end
  end

  describe 'basic validations' do
    subject(:reservation) { FactoryGirl.build(:valid_reservation) }
    it { is_expected.to belong_to(:equipment_model) }
    it { is_expected.to belong_to(:reserver) }
    it { is_expected.to belong_to(:equipment_item) }
    it { is_expected.to belong_to(:checkout_handler) }
    it { is_expected.to belong_to(:checkin_handler) }
    it { is_expected.to validate_presence_of(:equipment_model) }
  end

  describe '#approved?' do
    it 'returns false if requested' do
      res = FactoryGirl.build_stubbed(:request)
      expect(res.approved?).to be_falsey
    end
    it 'returns false if denied' do
      res = FactoryGirl.build_stubbed(:request, status: 'denied')
      expect(res.approved?).to be_falsey
    end
    it 'returns true if approved' do
      res = FactoryGirl.build_stubbed(:request, status: 'reserved')
      expect(res.approved?).to be_truthy
    end
    it 'returns false if not a request' do
      res = FactoryGirl.build_stubbed(:valid_reservation)
      expect(res.approved?).to be_falsey
    end
  end

  describe '#flagged?' do
    let!(:res) { FactoryGirl.build_stubbed(:valid_reservation) }
    it 'returns true when flagged' do
      res.flag(:request)
      expect(res.flagged?(:request)).to be_truthy
    end
    it 'returns false when not flagged' do
      expect(res.flagged?(:request)).to be_falsey
    end
    it 'returns false when the flag is undefined' do
      expect(res.flagged?(:garbage_flag)).to be_falsey
    end
  end

  describe '#attrs?' do
    it 'returns true when all attributes match' do
      attrs = { overdue: true, status: 'checked_out' }
      res = FactoryGirl.build_stubbed(:overdue_reservation)
      expect(res.attrs?(attrs)).to be_truthy
    end
    it 'returns false when one attribute does not match' do
      attrs = { overdue: true, status: 'checked_out' }
      res = FactoryGirl.build_stubbed(:checked_out_reservation)
      expect(res.attrs?(attrs)).to be_falsey
    end
  end

  describe '#overlaps_with' do
    let!(:res) do
      FactoryGirl.build_stubbed(:valid_reservation,
                                start_date: Time.zone.today,
                                due_date: Time.zone.today + 1.day)
    end
    it 'returns true when overlapping with date' do
      expect(res.overlaps_with(Time.zone.today)).to be_truthy
    end
    it 'returns false when not overlapping with date' do
      expect(res.overlaps_with(Time.zone.today - 1.day)).to be_falsey
    end
  end

  describe '#flag' do
    let!(:res) { FactoryGirl.build_stubbed(:valid_reservation) }
    it 'flags the reservation' do
      expect { res.flag(:request) }.to \
        change { res.flagged?(:request) }.from(false).to(true)
    end
    it 'does nothing if flag is undefined' do
      expect { res.flag(:garbage) }.not_to change { res.flags }
    end
    it 'does nothing if flag is already set' do
      res.flag(:request)
      expect { res.flag(:request) }.not_to change { res.flags }
    end
  end

  describe '#unflag' do
    let!(:res) { FactoryGirl.build_stubbed(:valid_reservation) }
    it 'unflags the reservation' do
      res.flag(:request)
      expect { res.unflag(:request) }.to \
        change { res.flagged?(:request) }.from(true).to(false)
    end
    it 'does nothing if flag is undefined' do
      expect { res.unflag(:garbage) }.not_to change { res.flags }
    end
    it 'does nothing if not flagged' do
      expect { res.unflag(:request) }.not_to change { res.flags }
    end
  end

  describe '.expire!' do
    let!(:res) do
      FactoryGirl.build_stubbed(:request).tap do |r|
        allow(r).to receive(:save)
      end
    end
    it 'updates the status' do
      expect { res.expire! }.to change { res.status }
        .from('requested').to('denied')
    end
    it 'flags as expired' do
      expect { res.expire! }.to change { res.flagged?(:expired) }
        .from(false).to(true)
    end
    it 'saves the result' do
      res.expire!
      expect(res).to have_received(:save)
    end
  end

  describe '#human_status' do
    shared_examples 'returns the proper string' do |string, type, **attrs|
      it do
        res = FactoryGirl.build_stubbed(type, **attrs)
        expect(res.human_status).to eq(string)
      end
    end
    it_behaves_like 'returns the proper string', 'starts today',
                    :valid_reservation, start_date: Time.zone.today
    it_behaves_like 'returns the proper string', 'reserved',
                    :valid_reservation, start_date: Time.zone.today + 1.day
    it_behaves_like 'returns the proper string', 'due today',
                    :checked_out_reservation, due_date: Time.zone.today
    it_behaves_like 'returns the proper string', 'checked_out',
                    :checked_out_reservation, due_date: Time.zone.today + 1.day
    it_behaves_like 'returns the proper string', 'returned overdue',
                    :overdue_returned_reservation
    it_behaves_like 'returns the proper string', 'overdue', :overdue_reservation
    it_behaves_like 'returns the proper string', 'missed', :missed_reservation
    it_behaves_like 'returns the proper string', 'returned',
                    :checked_in_reservation
    it_behaves_like 'returns the proper string', 'requested', :request
    it_behaves_like 'returns the proper string', 'denied', :request,
                    status: 'denied'
  end

  describe '#end_date' do
    context 'if checked in' do
      it 'returns the checkin date' do
        res = FactoryGirl.build_stubbed(:checked_in_reservation)
        expect(res.end_date).to eq(res.checked_in)
      end
      it 'does not care if overdue' do
        res = FactoryGirl.build_stubbed(:overdue_returned_reservation)
        expect(res.end_date).to eq(res.checked_in)
      end
    end
    it 'returns today if actively overdue' do
      res = FactoryGirl.build_stubbed(:overdue_reservation)
      expect(res.end_date).to eq(Time.zone.today)
    end
    it 'returns due date for request' do
      res = FactoryGirl.build_stubbed(:request)
      expect(res.end_date).to eq(res.due_date)
    end
    it 'returns due date for reserved' do
      res = FactoryGirl.build_stubbed(:valid_reservation)
      expect(res.end_date).to eq(res.due_date)
    end
  end

  describe '#duration' do
    it 'returns the length of the reservation' do
      res = FactoryGirl.build_stubbed(:valid_reservation,
                                      start_date: Time.zone.today,
                                      due_date: Time.zone.today + 1.day)
      length = 2
      expect(res.duration).to eq(length)
    end
  end

  describe '#time_checked_out' do
    it 'returns the length of the checkout for returned reservations' do
      res = FactoryGirl.build_stubbed(:checked_in_reservation,
                                      start_date: Time.zone.today - 3.days,
                                      due_date: Time.zone.today - 1.day,
                                      checked_out: Time.zone.today - 3.days,
                                      checked_in: Time.zone.today - 2.days)
      length = 2
      expect(res.time_checked_out).to eq(length)
    end
  end

  describe '#late_fee' do
    it 'returns the correct late fee' do
      fee_per_day = 5
      days = 3
      expected = fee_per_day * days
      model = FactoryGirl.build_stubbed(:equipment_model, late_fee: fee_per_day)
      res = FactoryGirl.build_stubbed(:overdue_reservation,
                                      equipment_model: model,
                                      due_date: Time.zone.today - days.days)
      expect(res.late_fee).to eq(expected)
    end
    it 'returns 0 if not overdue' do
      res = FactoryGirl.build_stubbed(:checked_out_reservation)
      expect(res.late_fee).to eq(0)
    end
    it 'returns the cap if a cap is set' do
      fee_per_day = 5
      days = 3
      cap = 10
      model = FactoryGirl.build_stubbed(:equipment_model,
                                        late_fee: fee_per_day,
                                        late_fee_max: cap)
      res = FactoryGirl.build_stubbed(:overdue_reservation,
                                      equipment_model: model,
                                      due_date: Time.zone.today - days.days)
      expect(res.late_fee).to eq(cap)
    end
  end

  describe '#reserver' do
    it 'returns the associated user' do
      user = FactoryGirl.create(:user)
      res = FactoryGirl.build_stubbed(:valid_reservation, reserver_id: user.id)
      expect(res.reserver).to eq(user)
    end
    it "returns a dummy user if there isn't one" do
      res = FactoryGirl.build_stubbed(:valid_reservation, reserver_id: nil)
      expect(res.reserver).to be_new_record
    end
  end

  describe '#find_renewal_date' do
    let!(:length) { 5 }
    let!(:model) do
      FactoryGirl.create(:equipment_model_with_item, max_renewal_length: length)
    end
    let!(:res) do
      FactoryGirl.build_stubbed(:valid_reservation,
                                reserver: FactoryGirl.create(:user),
                                equipment_model: model)
    end
    it 'sets the correct renewal length' do
      expect(res.find_renewal_date).to eq(res.due_date + length.days)
    end
    context 'with a blackout date overlapping with the max renewal length' do
      it 'sets the correct renewal length' do
        FactoryGirl.create(:blackout,
                           start_date: res.due_date + 2.days,
                           end_date: res.due_date + length.days + 1.day)
        expect(res.find_renewal_date).to eq(res.due_date + 1.day)
      end
    end
    context 'with a blackout date going right up to the max renewal length' do
      it 'sets a length of 0' do
        FactoryGirl.create(:blackout,
                           start_date: res.due_date + 1.day,
                           end_date: res.due_date + length.days + 1.day)
        expect(res.find_renewal_date).to eq(res.due_date)
      end
    end
    context 'with a future reservation on the same model' do
      it 'sets the correct renewal length' do
        FactoryGirl.create(:reservation,
                           equipment_model: model,
                           start_date: res.due_date + 3.days,
                           due_date: res.due_date + length.days + 1.day)
        expect(res.find_renewal_date).to eq(res.due_date + 2.days)
      end
    end
  end

  describe '#eligible_for_renew?' do
    shared_examples 'not checked out' do |type|
      it 'returns false' do
        expect(FactoryGirl.build_stubbed(type).eligible_for_renew?).to be_falsey
      end
    end
    %i[valid_reservation checked_in_reservation request].each do |type|
      it_behaves_like 'not checked out', type
    end
    it 'returns false when overdue' do
      res = FactoryGirl.build_stubbed(:overdue_reservation)
      expect(res.eligible_for_renew?).to be_falsey
    end
    it 'returns false when the reserver is banned' do
      user = FactoryGirl.create(:banned)
      res = FactoryGirl.build_stubbed(:checked_out_reservation, reserver: user)
      expect(res.eligible_for_renew?).to be_falsey
    end
    it 'returns false when the model cannot be renewed' do
      model = FactoryGirl.build_stubbed(:equipment_model,
                                        max_renewal_length: 0)
      res = FactoryGirl.build_stubbed(:checked_out_reservation,
                                      equipment_model: model)
      expect(res.eligible_for_renew?).to be_falsey
    end
    it 'returns false when there are no items available' do
      model = FactoryGirl.build_stubbed(:equipment_model)
      res = FactoryGirl.build_stubbed(:checked_out_reservation,
                                      equipment_model: model)
      allow(model).to receive(:num_available_on).with(res.due_date + 1.day)
                                                .and_return(0)
      expect(res.eligible_for_renew?).to be_falsey
    end
    it 'returns false when renewed more than the max allowed times' do
      model = FactoryGirl.build_stubbed(:equipment_model)
      res = FactoryGirl.build_stubbed(:checked_out_reservation,
                                      equipment_model: model,
                                      times_renewed: 1)
      allow(model).to receive(:num_available_on).with(res.due_date + 1.day)
                                                .and_return(1)
      allow(model).to receive(:maximum_renewal_times).and_return(1)
      expect(res.eligible_for_renew?).to be_falsey
    end
    it 'returns false before the eligible period' do
      model = FactoryGirl.build_stubbed(:equipment_model)
      res = FactoryGirl.build_stubbed(:checked_out_reservation,
                                      equipment_model: model,
                                      due_date: Time.zone.today + 2.days)
      allow(model).to receive(:num_available_on).with(res.due_date + 1.day)
                                                .and_return(1)
      allow(model).to receive(:maximum_renewal_times).and_return(1)
      allow(model).to receive(:maximum_renewal_days_before_due).and_return(1)
      expect(res.eligible_for_renew?).to be_falsey
    end
    it 'returns true when eligible' do
      model = FactoryGirl.build_stubbed(:equipment_model)
      res = FactoryGirl.build_stubbed(:checked_out_reservation,
                                      equipment_model: model,
                                      due_date: Time.zone.today + 2.days)
      allow(model).to receive(:num_available_on).with(res.due_date + 1.day)
                                                .and_return(1)
      allow(model).to receive(:maximum_renewal_times).and_return(1)
      allow(model).to receive(:maximum_renewal_days_before_due).and_return(3)
      expect(res.eligible_for_renew?).to be_truthy
    end
  end

  describe '#to_cart' do
    it 'returns a new cart object corresponding to the reservation' do
      res = FactoryGirl.build_stubbed(:valid_reservation,
                                      reserver: FactoryGirl.create(:user))
      cart = res.to_cart
      expect(cart).to be_kind_of(Cart)
      expect(cart.start_date).to eq(res.start_date)
      expect(cart.due_date).to eq(res.due_date)
      expect(cart.reserver_id).to eq(res.reserver.id)
      expect(cart.items).to eq(res.equipment_model_id => 1)
    end
  end

  describe '#renew' do
    let!(:user) { FactoryGirl.build_stubbed(:user) }
    it "doesn't renew if ineligible" do
      res = FactoryGirl.build_stubbed(:valid_reservation)
      allow(res).to receive(:eligible_for_renew?).and_return(false)
      expect(res.renew(user)).to match(/not eligible/)
    end
    context 'eligible for renew' do
      let!(:res) do
        FactoryGirl.build_stubbed(:valid_reservation,
                                  times_renewed: 0,
                                  notes: '')
      end
      let!(:new_date) { Time.zone.today + 5.days }
      before do
        allow(res).to receive(:eligible_for_renew?).and_return(true)
        allow(res).to receive(:find_renewal_date).and_return(new_date)
        allow(res).to receive(:save)
      end
      it 'updates the due date' do
        old_date = res.due_date
        expect { res.renew(user) }.to change { res.due_date }
          .from(old_date).to(new_date)
      end
      it 'increments times_renewed' do
        expect { res.renew(user) }.to change { res.times_renewed }.by(1)
      end
      it 'updates the notes' do
        time_string = Time.zone.now.to_s(:long)
        due_date_string = new_date.to_s(:long)
        allow(user).to receive(:md_link).and_return('md link')
        res.renew(user)
        expect(res.notes).to match(time_string)
        expect(res.notes).to match(due_date_string)
        expect(res.notes).to match(/md link/)
        expect(res.notes).to match(/Renewed/)
      end
      it 'returns nil when successful' do
        allow(res).to receive(:save).and_return(true)
        expect(res.renew(user)).to be_nil
      end
      it 'returns error if unsuccessful' do
        allow(res).to receive(:save).and_return(false)
        expect(res.renew(user)).to be_kind_of(String)
      end
    end
  end

  describe '#checkin' do
    let!(:handler) { FactoryGirl.build_stubbed(:checkout_person) }
    context 'no procedures' do
      let!(:res) { FactoryGirl.build_stubbed(:checked_out_reservation) }
      let(:procedures) { instance_spy(ActionController::Parameters, to_h: {}) }
      it 'sets the checkin handler' do
        expect { res.checkin(handler, procedures, '') }.to \
          change { res.checkin_handler }.from(nil).to(handler)
      end
      it 'sets the checked in time' do
        # travel in order to freeze the time
        travel(-1.days) do
          expect { res.checkin(handler, procedures, '') }.to \
            change { res.checked_in }.from(nil).to(Time.zone.now)
        end
      end
      it 'sets the status to returned' do
        expect { res.checkin(handler, procedures, '') }.to \
          change { res.status }.from('checked_out').to('returned')
      end
      it 'updates the notes' do
        # FIXME: might fall under overtesting (testing messages sent to self)
        # but notes handling will be handled by a separate module in the future
        # alternatively just test that the notes change?
        # also applies to the next two tests
        new_notes = ''
        procedures = instance_spy(ActionController::Parameters, to_h: {})
        allow(res).to receive(:make_notes)
          .with('Checked in', new_notes, [], handler)
        res.checkin(handler, procedures, new_notes)
        expect(res).to have_received(:make_notes)
          .with('Checked in', new_notes, [], handler)
      end
      it 'returns the reservation' do
        expect(res.checkin(handler, procedures, '')).to eq(res)
      end
    end
    context 'with completed procedures' do
      it 'sends no procedures to the notes' do
        # FIXME: this part of the method is really in need of refactoring
        procedure = FactoryGirl.create(:checkin_procedure)
        model = EquipmentModel.find(procedure.equipment_model.id)
        res = FactoryGirl.build_stubbed(:checked_out_reservation,
                                        equipment_model: model)
        p_hash = { procedure.id.to_s => '1' }
        procedures = instance_spy(ActionController::Parameters, to_h: p_hash)
        allow(res).to receive(:make_notes).with('Checked in', '', [], handler)
        res.checkin(handler, procedures, '')
        expect(res).to have_received(:make_notes)
          .with('Checked in', '', [], handler)
      end
    end
    context 'with incomplete procedures' do
      it 'sends the incomplete procedures to the notes' do
        # FIXME: this part of the method is really in need of refactoring
        procedure = FactoryGirl.create(:checkin_procedure)
        model = EquipmentModel.find(procedure.equipment_model.id)
        res = FactoryGirl.build_stubbed(:checked_out_reservation,
                                        equipment_model: model)
        procedures = instance_spy(ActionController::Parameters, to_h: {})
        incomplete = [procedure.step]
        allow(res).to receive(:make_notes)
          .with('Checked in', '', incomplete, handler)
        res.checkin(handler, procedures, '')
        expect(res).to have_received(:make_notes)
          .with('Checked in', '', incomplete, handler)
      end
    end
    context 'overdue' do
      let!(:res) { FactoryGirl.create(:overdue_reservation) }
      let(:procedures) { instance_spy(ActionController::Parameters, to_h: {}) }
      before do
        ActionMailer::Base.perform_deliveries = false
        mock_app_config(admin_email: 'admin@email.com',
                        disable_user_emails: false)
      end
      after do
        ActionMailer::Base.perform_deliveries = true
      end
      it 'sends the admins an email' do
        expect(AdminMailer).to \
          receive_message_chain(:overdue_checked_in_fine_admin, :deliver_now)
        res.checkin(handler, procedures, '')
      end
      it 'sends the user an email' do
        expect(UserMailer).to \
          receive_message_chain(:reservation_status_update, :deliver_now)
        res.checkin(handler, procedures, '')
      end
    end
  end

  describe '#checkout' do
    let!(:handler) { FactoryGirl.build_stubbed(:checkout_person) }
    context 'no procedures' do
      let!(:model) { FactoryGirl.build_stubbed(:equipment_model) }
      let!(:res) do
        FactoryGirl.build_stubbed(:valid_reservation, equipment_model: model)
      end
      let!(:item) do
        FactoryGirl.build_stubbed(:equipment_item, equipment_model: model)
      end
      let(:procedures) { instance_spy(ActionController::Parameters, to_h: {}) }
      it 'sets the checkout handler' do
        expect { res.checkout(item.id, handler, procedures, '') }.to \
          change { res.checkout_handler }.from(nil).to(handler)
      end
      it 'sets the checked out time' do
        # travel in order to freeze the time
        travel(-1.days) do
          expect { res.checkout(item.id, handler, procedures, '') }.to \
            change { res.checked_out }.from(nil).to(Time.zone.now)
        end
      end
      it 'sets the status to checked_out' do
        expect { res.checkout(item.id, handler, procedures, '') }.to \
          change { res.status }.from('reserved').to('checked_out')
      end
      it 'assigns the item' do
        expect { res.checkout(item.id, handler, procedures, '') }.to \
          change { res.equipment_item_id }.from(nil).to(item.id)
      end
      it 'updates the notes' do
        # FIXME: might fall under overtesting (testing messages sent to self)
        # but notes handling will be handled by a separate module in the future
        # alternatively just test that the notes change?
        # also applies to the next two tests
        new_notes = ''
        procedures = instance_spy(ActionController::Parameters, to_h: {})
        allow(res).to receive(:make_notes)
          .with('Checked out', new_notes, [], handler)
        res.checkout(item, handler, procedures, new_notes)
        expect(res).to have_received(:make_notes)
          .with('Checked out', new_notes, [], handler)
      end
      it 'returns the reservation' do
        expect(res.checkout(item, handler, procedures, '')).to eq(res)
      end
    end
    context 'with completed procedures' do
      it 'sends no procedures to the notes' do
        # FIXME: this part of the method is really in need of refactoring
        procedure = FactoryGirl.create(:checkout_procedure)
        model = EquipmentModel.find(procedure.equipment_model.id)
        item = FactoryGirl.build_stubbed(:equipment_item,
                                         equipment_model: model)
        res = FactoryGirl.build_stubbed(:valid_reservation,
                                        equipment_model: model)
        p_hash = { procedure.id.to_s => '1' }
        procedures = instance_spy(ActionController::Parameters, to_h: p_hash)

        allow(res).to receive(:make_notes).with('Checked out', '', [], handler)
        res.checkout(item, handler, procedures, '')
        expect(res).to have_received(:make_notes)
          .with('Checked out', '', [], handler)
      end
    end
    context 'with incomplete procedures' do
      it 'sends the incomplete procedures to the notes' do
        # FIXME: this part of the method is really in need of refactoring
        procedure = FactoryGirl.create(:checkout_procedure)
        model = EquipmentModel.find(procedure.equipment_model.id)
        item = FactoryGirl.build_stubbed(:equipment_item,
                                         equipment_model: model)
        res = FactoryGirl.build_stubbed(:valid_reservation,
                                        equipment_model: model)
        procedures = instance_spy(ActionController::Parameters, to_h: {})
        incomplete = [procedure.step]
        allow(res).to receive(:make_notes)
          .with('Checked out', '', incomplete, handler)
        res.checkout(item, handler, procedures, '')
        expect(res).to have_received(:make_notes)
          .with('Checked out', '', incomplete, handler)
      end
    end
  end

  describe '#archive' do
    let!(:archiver) { FactoryGirl.build_stubbed(:user) }
    it 'returns the reservation' do
      res = FactoryGirl.build_stubbed(:valid_reservation)
      expect(res.archive(archiver, '')).to eq(res)
    end
    context 'not checked in' do
      context 'not checked out' do
        it 'sets checked_out to now' do
          travel(-1.days) do
            res = FactoryGirl.build_stubbed(:valid_reservation)
            expect { res.archive(archiver, '') }.to change { res.checked_out }
              .from(nil).to(Time.zone.now)
          end
        end
      end
      it 'sets checked_in to now' do
        travel(-1.days) do
          res = FactoryGirl.build_stubbed(:checked_out_reservation)
          expect { res.archive(archiver, '') }.to change { res.checked_in }
            .from(nil).to(Time.zone.now)
        end
      end
      it 'updates the notes' do
        travel(-1.days) do
          res = FactoryGirl.build_stubbed(:checked_out_reservation)
          allow(archiver).to receive(:md_link).and_return('md link')
          note = 'note'
          archive_time = Time.zone.now.to_s(:long)
          res.archive(archiver, note)
          expect(res.notes).to include(note)
          expect(res.notes).to include('md link')
          expect(res.notes).to include(archive_time)
        end
      end
      it 'sets the status to archived' do
        res = FactoryGirl.build_stubbed(:checked_out_reservation)
        expect { res.archive(archiver, '') }.to change { res.status }
          .from('checked_out').to('archived')
      end
    end
    context 'checked in' do
      it 'does nothing' do
        res = FactoryGirl.build_stubbed(:checked_in_reservation)
        expect { res.archive(archiver, '') }.not_to change { res.status }
      end
    end
  end

  describe '#update' do
    let!(:user) { FactoryGirl.build_stubbed(:user) }
    it 'does nothing when no changes and no new notes' do
      res = FactoryGirl.build_stubbed(:valid_reservation)
      expect { res.update(user, {}, '') }.not_to change { res.notes }
    end
    it 'updates with given notes' do
      res = FactoryGirl.build_stubbed(:valid_reservation)
      res.update(user, {}, 'test_note')
      expect(res.notes).to include('test_note')
    end
    it 'notes the editing user' do
      res = FactoryGirl.build_stubbed(:valid_reservation)
      allow(user).to receive(:md_link).and_return('md link')
      res.update(user, {}, 'test_note')
      expect(res.notes).to include('md link')
    end
    shared_examples 'notes change with md link' do |factory, attr|
      it do
        old = FactoryGirl.create(factory)
        new = FactoryGirl.create(factory)
        res = FactoryGirl.build_stubbed(:valid_reservation, attr => old.id)
        res.update(user, { attr => new.id }, '')
        expect(res.notes).to include(old.md_link)
        expect(res.notes).to include(new.md_link)
      end
    end
    it_behaves_like 'notes change with md link', :user, :reserver_id
    it_behaves_like 'notes change with md link', :equipment_item,
                    :equipment_item_id
    shared_examples 'notes changed date' do |attr|
      it do
        old = Time.zone.today + 3.days
        new = Time.zone.today + 2.days
        res = FactoryGirl.build_stubbed(:valid_reservation, attr => old)
        res.update(user, { attr => new }, '')
        expect(res.notes).to include(old.to_s(:long))
        expect(res.notes).to include(new.to_s(:long))
      end
    end
    it_behaves_like 'notes changed date', :start_date
    it_behaves_like 'notes changed date', :due_date
    context 'changed to not overdue' do
      it 'notes the change' do
        res = FactoryGirl.build_stubbed(:overdue_reservation)
        new_date = Time.zone.today + 1.day
        res.update(user, { due_date: new_date }, '')
        expect(res.notes).to include('marked as not overdue')
      end
    end
    context 'changed to overdue' do
      it 'notes the change' do
        res = FactoryGirl.build_stubbed(:checked_out_reservation)
        new_date = Time.zone.today - 1.day
        res.update(user, { due_date: new_date }, '')
        expect(res.notes).not_to include('marked as not overdue')
        expect(res.notes).to include('marked as overdue')
      end
    end
  end

  describe '#make_notes' do
    let!(:user) { FactoryGirl.build_stubbed(:user) }
    it 'notes the user' do
      res = FactoryGirl.build_stubbed(:valid_reservation)
      allow(user).to receive(:md_link).and_return('md link')
      res.make_notes('', '', [], user)
      expect(res.notes).to include('md link')
    end
    it 'notes the type of action' do
      res = FactoryGirl.build_stubbed(:valid_reservation)
      res.make_notes('procedure', '', [], user)
      expect(res.notes).to include('procedure')
    end
    context 'no new notes or incomplete procedures' do
      it 'sets notes_unsent to false' do
        res = FactoryGirl.build_stubbed(:valid_reservation)
        res.make_notes('', '', [], user)
        expect(res.notes_unsent).to be_falsey
      end
      it 'notes that all procedures were completed' do
        res = FactoryGirl.build_stubbed(:valid_reservation)
        res.make_notes('', '', [], user)
        expect(res.notes).to include('All procedures were performed')
      end
    end
    context 'new notes' do
      it 'adds them' do
        res = FactoryGirl.build_stubbed(:valid_reservation)
        res.make_notes('', 'test_note', [], user)
        expect(res.notes).to include('test_note')
      end
    end
    context 'incomplete procedures' do
      it 'adds them' do
        res = FactoryGirl.build_stubbed(:valid_reservation)
        res.make_notes('', '', ['incomplete'], user)
        expect(res.notes).to include('procedures were not performed')
        expect(res.notes).to include('incomplete')
      end
    end
  end
end
