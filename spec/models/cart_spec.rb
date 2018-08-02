# frozen_string_literal: true

require 'spec_helper'

describe Cart, type: :model do
  before(:each) do
    @cart = FactoryGirl.build(:cart)
    @cart.items = {} # Needed to avoid db flushing problems
  end

  it 'has a working factory' do
    expect(@cart).to be_valid
  end

  context 'General validations' do
    it { is_expected.to validate_presence_of(:reserver_id) }
    it { is_expected.to validate_presence_of(:start_date) }
    it { is_expected.to validate_presence_of(:due_date) }
  end

  describe '.initialize' do
    it 'has no items' do
      @cart.items.nil?
    end
    it 'starts today ' do
      @cart.start_date == Time.zone.today
    end
    it 'is due tomorrow' do
      @cart.due_date == Time.zone.today + 1.day
    end
    it 'has no reserver' do
      @cart.reserver_id.nil?
    end
    it 'has errors' do
      @cart.errors.count > 0
    end
  end

  describe '.persisted?' do
    it { expect(@cart.persisted?).to be_falsey }
  end

  describe 'Item handling' do
    before(:each) do
      @equipment_model = FactoryGirl.create(:equipment_model)
    end

    describe '.add_item' do
      it 'adds an item' do
        @cart.add_item(@equipment_model)
        expect(@cart.items).to include(@equipment_model.id)
      end
      it 'increments if an item is already present' do
        @cart.add_item(@equipment_model)
        @cart.add_item(@equipment_model)
        expect(@cart.items[@equipment_model.id]).to eq(2)
      end
    end
  end

  describe 'Cart actions' do
    describe '.purge_all' do
      it 'should empty the items hash' do
        @cart.purge_all
        expect(@cart.items).to be_empty
      end
    end

    describe '.prepare_all' do
      before(:each) do
        @equipment_model = FactoryGirl.create(:equipment_model)
        @cart.add_item(@equipment_model)
        @cart.add_item(@equipment_model)
        @equipment_model2 = FactoryGirl.create(:equipment_model)
        @cart.add_item(@equipment_model2)
        @cart.start_date = Time.zone.today
        @cart.due_date = Time.zone.today + 1.day
        @cart.reserver_id = FactoryGirl.create(:user).id
      end
      it 'should create an array of reservations' do
        expect(@cart.prepare_all.class).to eq(Array)
        expect(@cart.prepare_all.first.class).to eq(Reservation)
      end
      describe 'the reservations' do
        it 'should have the correct dates' do
          array = @cart.prepare_all
          array.each do |r|
            expect(r.start_date).to eq(Time.zone.today)
            expect(r.due_date).to eq(Time.zone.today + 1.day)
          end
        end
        it 'should have the correct equipment models' do
          array = @cart.prepare_all
          expect(@cart.items).to include(array[1].equipment_model.id)
          expect(@cart.items).to include(array[0].equipment_model.id)
          expect(@cart.items).to include(array[2].equipment_model.id)
        end
        it 'should have the correct reserver ids' do
          array = @cart.prepare_all
          array.each do |r|
            expect(r.reserver_id).to eq @cart.reserver_id
          end
        end
      end
    end
  end

  describe 'Aliases' do
    describe '.duration' do
      it 'should calculate the sum correctly' do
        expect(@cart.duration).to eq(@cart.due_date - @cart.start_date + 1)
      end
    end

    describe '.reserver' do
      it 'should return a correct user instance' do
        expect(@cart.reserver).to eq(User.find(@cart.reserver_id))
      end
    end
  end

  describe '.empty?' do
    it 'is true when there are no items in cart' do
      @cart.items = []
      expect(@cart.empty?).to be_truthy
    end
    it 'is false when there are some items in cart' do
      @cart.add_item(FactoryGirl.create(:equipment_model))
      expect(@cart.empty?).to be_falsey
    end
  end

  describe 'fix_items' do
    it 'removes meaningless items' do
      @em = FactoryGirl.create(:equipment_model)
      @cart.add_item(@em)
      @em.destroy(:force)
      expect { @cart.fix_items }.to change { @cart.items.length }.by(-1)
    end
  end

  describe 'check_availability' do
    before(:each) do
      @em = FactoryGirl.create(:equipment_model)
      FactoryGirl.create(:equipment_item, equipment_model: @em)
      @cart.add_item(@em)
    end

    shared_examples 'validates availability' do |offset|
      before do
        @start_date = @cart.start_date - offset
        @due_date = @cart.due_date + offset
      end

      it 'fails if there is a reserved reservation for that model' do
        FactoryGirl.build(:reservation, equipment_model: @em,
                                        start_date: @start_date,
                                        due_date: @due_date)
                   .save(validate: false)

        expect(@cart.check_availability).not_to eq([])
        expect(@cart.validate_all).not_to eq([])
      end

      it 'fails if there is a checked out reservation for that model' do
        FactoryGirl.build(:checked_out_reservation,
                          equipment_model: @em, start_date: @start_date,
                          due_date: @due_date,
                          equipment_item: @em.equipment_items.first)
                   .save(validate: false)

        expect(@cart.check_availability).not_to eq([])
        expect(@cart.validate_all).not_to eq([])
      end
    end

    it 'passes if there are equipment items available' do
      expect(@cart.check_availability).to eq([])
    end

    it_behaves_like 'validates availability', 0.days
    it_behaves_like 'validates availability', 1.day
  end

  describe 'check_consecutive' do
    before(:each) do
      @em = FactoryGirl.create(:equipment_model)
      FactoryGirl.create_pair(:equipment_item, equipment_model: @em)
      @cart.add_item(@em)
    end

    shared_examples 'with a consecutive reservation' do |res_type|
      before do
        @em.update_attributes(max_per_user: 1, max_checkout_length: 3)
        @res = FactoryGirl.create(res_type,
                                  reserver: User.find_by(id: @cart.reserver.id),
                                  equipment_model: @em,
                                  start_date: @cart.due_date + 1,
                                  due_date: @cart.due_date + 2)
      end

      it 'fails when the reservation is before' do
        # rubocop:disable Rails/SkipsModelValidations
        @res.update_columns(start_date: @cart.start_date - 2,
                            due_date: @cart.start_date - 1)
        # rubocop:enable Rails/SkipsModelValidations
        expect(@cart.check_consecutive).not_to eq([])
        expect(@cart.validate_all).not_to eq([])
      end

      it 'fails when the reservation is after' do
        expect(@cart.check_consecutive).not_to eq([])
        expect(@cart.validate_all).not_to eq([])
      end

      it 'fails when there are reservations before and after' do
        @em.update_attributes(max_checkout_length: 5)
        FactoryGirl.build(res_type,
                          reserver: User.find_by(id: @cart.reserver.id),
                          equipment_model: @em,
                          start_date: @cart.start_date - 2,
                          due_date: @cart.start_date - 1).save(validate: false)
        expect(@cart.check_consecutive).not_to eq([])
        expect(@cart.validate_all).not_to eq([])
      end

      it 'passes when checking a renewal' do
        expect(@cart.check_consecutive).not_to eq([])
        expect(@cart.validate_all(true)).to eq([])
      end

      it "passes when max_per_user isn't 1" do
        @em.update_attributes(max_per_user: 5)
        expect(@em.max_per_user).not_to eq(1)
        expect(@cart.check_consecutive).to eq([])
      end

      it "passes when it doesn't exceed the max_checkout_length" do
        @em.update_attributes(max_checkout_length: 5)
        expect(@em.max_checkout_length).to eq(5)
        expect(@cart.check_consecutive).to eq([])
      end
    end

    it 'passes without a consecutive reservation' do
      expect(@cart.check_consecutive).to eq([])
    end

    it_behaves_like 'with a consecutive reservation', :valid_reservation
    it_behaves_like 'with a consecutive reservation', :checked_out_reservation
  end
  describe 'check_max_ems' do
    before(:each) do
      @em = FactoryGirl.create(:equipment_model, max_per_user: 1)
      FactoryGirl.create_pair(:equipment_item, equipment_model: @em)
      @cart.add_item(@em)
    end
    it "passes when the reserver doesn't exceed the item limit" do
      expect(@cart.check_max_ems).to eq([])
    end
    it 'passes when the cart contains multiple models' do
      em2 = FactoryGirl.create(:equipment_model, max_per_user: 1)
      FactoryGirl.create_pair(:equipment_item, equipment_model: em2)
      @cart.add_item(em2)
      expect(@cart.check_max_ems).to eq([])
    end
    it 'fails when the reserver exceeds the item limit' do
      FactoryGirl.create(:valid_reservation,
                         reserver: User.find_by(id: @cart.reserver_id),
                         equipment_model: @em)
      expect(@cart.check_max_ems).not_to eq([])
    end
    it 'fails when the reserver exceeds the item limit with an overdue res' do
      FactoryGirl.create(:overdue_reservation,
                         reserver: User.find_by(id: @cart.reserver_id),
                         equipment_model: @em)
      expect(@cart.check_max_ems).not_to eq([])
    end

    context 'reserver has unrelated reservation' do
      it 'passes' do
        other_em = FactoryGirl.create(:equipment_model)
        reserver = User.find(@cart.reserver_id)
        FactoryGirl.create(:valid_reservation, reserver: reserver,
                                               equipment_model: other_em)
        expect(@cart.check_max_ems).to be_empty
      end
    end
  end
  describe 'check_max_cat' do
    before(:each) do
      @cat = FactoryGirl.create(:category, max_per_user: 1)
      @ems = FactoryGirl.create_pair(:equipment_model, category: @cat)
      @ems.each do |em|
        FactoryGirl.create_pair(:equipment_item, equipment_model: em)
      end
      @cart.add_item(@ems.first)
    end
    it "passes when the reserver doesn't exceed the item limit" do
      expect(@cart.check_max_cat).to eq([])
    end
    it 'passes when the cart has items from multiple categories' do
      cat2 = FactoryGirl.create(:category, max_per_user: 1)
      em3 = FactoryGirl.create(:equipment_model, category: cat2)
      FactoryGirl.create_pair(:equipment_item, equipment_model: em3)
      @cart.add_item(em3)
      expect(@cart.check_max_cat).to eq([])
    end
    it 'fails when the reserver exceeds the item limit' do
      FactoryGirl.create(:valid_reservation,
                         reserver: User.find_by(id: @cart.reserver_id),
                         equipment_model: @ems.last)
      expect(@cart.check_max_cat).not_to eq([])
    end
    it 'fails when the reserver exceeds the item limit with an overdue res' do
      FactoryGirl.create(:overdue_reservation,
                         reserver: User.find_by(id: @cart.reserver_id),
                         equipment_model: @ems.last)
      expect(@cart.check_max_cat).not_to eq([])
    end
    context 'reserver has unrelated reservation' do
      it 'passes' do
        other_cat = FactoryGirl.create(:equipment_model,
                                       category: FactoryGirl.create(:category))
        reserver = User.find(@cart.reserver_id)
        FactoryGirl.create(:valid_reservation, reserver: reserver,
                                               equipment_model: other_cat)
        expect(@cart.check_max_cat).to be_empty
      end
    end
  end
end
