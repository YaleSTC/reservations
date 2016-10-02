# frozen_string_literal: true
require 'spec_helper'
require 'concerns/linkable_spec.rb'

describe EquipmentModel, type: :model do
  it_behaves_like 'linkable'
  def mock_eq_model(**attrs)
    FactoryGirl.build_stubbed(:equipment_model, **attrs)
  end

  it 'has a working factory' do
    expect(FactoryGirl.create(:equipment_model)).to be_truthy
  end

  describe 'basic validations' do
    let!(:model) { mock_eq_model }
    it { is_expected.to have_and_belong_to_many(:requirements) }
    it { is_expected.to have_many(:equipment_items) }
    it { is_expected.to have_many(:reservations) }
    it { is_expected.to have_many(:checkin_procedures) }
    it { is_expected.to accept_nested_attributes_for(:checkin_procedures) }
    it { is_expected.to have_many(:checkout_procedures) }
    it { is_expected.to accept_nested_attributes_for(:checkout_procedures) }
    it { is_expected.to have_and_belong_to_many(:associated_equipment_models) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to belong_to(:category) }
    it 'requires an associated category' do
      model.category = nil
      expect(model.valid?).to be_falsey
    end
  end

  describe 'attribute-specific validations' do
    shared_examples 'integer attribute' do |attr|
      it 'is valid with an integer value' do
        model = mock_eq_model(attr => 2)
        expect(model.valid?).to be_truthy
      end
      it 'is not valid with a non integer value' do
        model = mock_eq_model(attr => 2.3)
        expect(model.valid?).to be_falsey
      end
      it 'is not valid when negative' do
        model = mock_eq_model(attr => -1)
        expect(model.valid?).to be_falsey
      end
      it 'is valid when nil' do
        model = mock_eq_model(attr => nil)
        expect(model.valid?).to be_truthy
      end
    end
    shared_examples 'allows 0' do |attr|
      it 'is valid when 0' do
        model = mock_eq_model(attr => 0)
        expect(model.valid?).to be_truthy
      end
    end
    shared_examples 'does not allow 0' do |attr|
      it 'is not valid when 0' do
        model = mock_eq_model(attr => 0)
        expect(model.valid?).to be_falsey
      end
    end
    describe 'max_per_user' do
      it_behaves_like 'integer attribute', :max_per_user
      it_behaves_like 'does not allow 0', :max_per_user
    end
    describe 'max_renewal_length' do
      it_behaves_like 'integer attribute', :max_renewal_length
      it_behaves_like 'allows 0', :max_renewal_length
    end
    describe 'max_renewal_times' do
      it_behaves_like 'integer attribute', :max_renewal_times
      it_behaves_like 'allows 0', :max_renewal_times
    end
    describe 'renewal_days_before_due' do
      it_behaves_like 'integer attribute', :renewal_days_before_due
      it_behaves_like 'allows 0', :renewal_days_before_due
    end
    shared_examples 'string attribute' do |attr|
      it 'fails when less than 0' do
        model = mock_eq_model(attr => '-1.00')
        expect(model.valid?).to be_falsey
      end
      it 'can be 0' do
        model = mock_eq_model(attr => '0.00')
        expect(model.valid?).to be_truthy
      end
    end
    describe 'late fee' do
      it_behaves_like 'string attribute', :late_fee
    end
    describe 'replacement fee' do
      it_behaves_like 'string attribute', :replacement_fee
    end
  end

  describe 'association validations' do
    let!(:unique_id) { FactoryGirl.generate(:unique_id) }
    it 'does not permit association with itself' do
      model = FactoryGirl.create(:equipment_model, id: unique_id)
      model.associated_equipment_model_ids = [unique_id]
      expect(model.save).to be_falsey
    end
    describe '.not_associated_with_self' do
      it 'creates an error if associated with self' do
        model = FactoryGirl.create(:equipment_model, id: unique_id)
        model.associated_equipment_model_ids = [unique_id]
        expect { model.not_associated_with_self }.to \
          change { model.errors }
      end
    end
  end

  describe '#catalog_search' do
    it 'return equipment_models with all of the query words in '\
      'either name or description' do
      model = FactoryGirl.create(:equipment_model, name: 'Tumblr hipster',
                                                   description: 'jean shorts')
      another = FactoryGirl.create(:equipment_model, name: 'Tumblr starbucks',
                                                     description: 'jean bag')
      expect(EquipmentModel.catalog_search('Tumblr jean')).to\
        eq([model, another])
    end
    it 'does not return any equipment_models without every query word '\
      'in the name or description' do
      model = FactoryGirl.create(:equipment_model, name: 'Tumblr hipster',
                                                   description: 'jean shorts')
      another = FactoryGirl.create(:equipment_model, name: 'Tumblr starbucks',
                                                     description: 'jean bag')
      expect(EquipmentModel.catalog_search('starbucks')).to eq([another])
      expect(EquipmentModel.catalog_search('Tumblr hipster')).to eq([model])
    end
  end

  describe 'attribute inheritance methods' do
    shared_examples 'inherits from category' do |method, attr|
      it 'returns the value if set' do
        model = mock_eq_model
        expect(model.send(method)).to eq(model.send(attr))
      end
      it 'returns the category value if nil' do
        category = FactoryGirl.build_stubbed(:category)
        model = mock_eq_model(category: category, attr => nil)
        expect(model.send(method)).to eq(category.send(method))
      end
    end
    describe '.maximum_per_user' do
      it_behaves_like 'inherits from category', :maximum_per_user, :max_per_user
    end
    describe '.maximum_renewal_length' do
      it_behaves_like 'inherits from category', :maximum_renewal_length,
                      :max_renewal_length
    end
    describe '.maximum_renewal_times' do
      it_behaves_like 'inherits from category', :maximum_renewal_times,
                      :max_renewal_times
    end
    describe '.maximum_renewal_days_before_due' do
      it_behaves_like 'inherits from category',
                      :maximum_renewal_days_before_due,
                      :renewal_days_before_due
    end
  end

  describe '.model_restricted?' do
    it 'returns false if the user has fulfilled the requirements '\
      'to use the model' do
      req = [FactoryGirl.build_stubbed(:requirement)]
      user = FactoryGirl.build_stubbed(:user, requirements: req)
      allow(User).to receive(:find).with(user.id).and_return(user)
      model = mock_eq_model(requirements: req)
      expect(model.model_restricted?(user.id)).to be_falsey
    end
    it 'returns false if the model has no requirements' do
      user = FactoryGirl.build_stubbed(:user)
      allow(User).to receive(:find).with(user.id).and_return(user)
      model = mock_eq_model
      expect(model.model_restricted?(user.id)).to be_falsey
    end
    it 'returns true if the user has not fulfilled all of the requirements' do
      req = Array.new(2) { FactoryGirl.build_stubbed(:requirement) }
      user = FactoryGirl.build_stubbed(:user, requirements: [req.first])
      allow(User).to receive(:find).with(user.id).and_return(user)
      model = mock_eq_model(requirements: req)
      expect(model.model_restricted?(user.id)).to be_truthy
    end
    it 'returns true if the user has not fulfilled any of the requirements' do
      req = Array.new(2) { FactoryGirl.build_stubbed(:requirement) }
      user = FactoryGirl.build_stubbed(:user)
      allow(User).to receive(:find).with(user.id).and_return(user)
      model = mock_eq_model(requirements: req)
      expect(model.model_restricted?(user.id)).to be_truthy
    end
  end

  context 'methods involving reservations' do
    ACTIVE = [:valid_reservation, :checked_out_reservation].freeze
    INACTIVE = [:checked_in_reservation, :overdue_returned_reservation,
                :missed_reservation, :request].freeze
    describe '.num_available' do
      shared_examples 'overlapping' do |type, start_offset, due_offset|
        it 'is correct' do
          model = FactoryGirl.create(:equipment_model)
          res = FactoryGirl.create(type, equipment_model: model)
          expect(model.num_available(res.start_date + start_offset,
                                     res.due_date + due_offset)).to eq(0)
        end
      end
      shared_examples 'with an active reservation' do |type|
        it 'is correct with no overlap' do
          model = FactoryGirl.create(:equipment_model)
          res = FactoryGirl.create(type, equipment_model: model)
          expect(model.num_available(res.due_date + 1.day,
                                     res.due_date + 2.days)).to eq(1)
        end
        it_behaves_like 'overlapping', type, 0.days, 0.days
        it_behaves_like 'overlapping', type, 1.day, 1.day
        it_behaves_like 'overlapping', type, -1.days, 1.day
      end

      ACTIVE.each { |s| it_behaves_like 'with an active reservation', s }

      context 'when requests_affect_availability is set' do
        before { mock_app_config(requests_affect_availability: true) }
        it_behaves_like 'with an active reservation', :request
      end

      context 'with a checked-out, overdue reservation' do
        it 'is correct with no overlap' do
          model = FactoryGirl.create(:equipment_model)
          res = FactoryGirl.create(:overdue_reservation, equipment_model: model)
          expect(model.num_available(res.due_date + 1.day,
                                     res.due_date + 2.days)).to eq(0)
        end
        it_behaves_like 'overlapping', :overdue_reservation, 0.days, 0.days
        it_behaves_like 'overlapping', :overdue_reservation, 1.day, 1.day
        it_behaves_like 'overlapping', :overdue_reservation, -1.days, 1.day
      end

      shared_examples 'with an inactive reservation' do |type|
        it 'is correct with no overlap' do
          model = FactoryGirl.create(:equipment_model)
          res = FactoryGirl.create(type, equipment_model: model)
          expect(model.num_available(res.due_date + 1.day,
                                     res.due_date + 2.days)).to eq(1)
        end
        it 'is correct with overlap' do
          model = FactoryGirl.create(:equipment_model)
          res = FactoryGirl.create(type, equipment_model: model)
          expect(model.num_available(res.start_date, res.due_date)).to eq(1)
        end
      end

      INACTIVE.each { |s| it_behaves_like 'with an inactive reservation', s }
    end
    describe '.num_available_on' do
      it 'correctly calculates the number of items available' do
        model = FactoryGirl.create(:equipment_model)
        FactoryGirl.create_list(:equipment_item, 4, equipment_model: model)
        FactoryGirl.create(:valid_reservation, equipment_model: model)
        FactoryGirl.create(:checked_out_reservation, equipment_model: model)
        FactoryGirl.create(:overdue_reservation, equipment_model: model)
        expect(model.num_available_on(Time.zone.today)).to eq(1)
      end
    end
    describe '.available_item_select_options' do
      it 'makes a string listing the available items' do
        model = FactoryGirl.create(:equipment_model)
        FactoryGirl.create(:checked_out_reservation, equipment_model: model)
        item = FactoryGirl.create(:equipment_item, equipment_model: model)
        expect(model.available_item_select_options).to \
          eq("<option value=#{item.id}>#{item.name}</option>")
      end
    end
    describe 'destroy' do
      it 'destroys the model' do
        model = FactoryGirl.create(:equipment_model)
        expect(model.destroy).to be_truthy
      end
    end
  end
end
