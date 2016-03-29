# frozen_string_literal: true
require 'spec_helper'

describe OrderingHelper do
  let!(:current_user) { UserMock.new }
  describe 'successor and predecessor' do
    it 'yields the successor correctly' do
      category = FactoryGirl.create(:category)
      eq_model1 = FactoryGirl.create(:equipment_model,
                                     category: category,
                                     ordering: 1)
      eq_model2 = FactoryGirl.create(:equipment_model,
                                     category: category,
                                     ordering: 2)
      expect(OrderingHelper.new(eq_model2).successor).to eq(eq_model1)
    end
    it 'yields the predecessor correctly' do
      category = FactoryGirl.create(:category)
      eq_model1 = FactoryGirl.create(:equipment_model,
                                     category: category,
                                     ordering: 1)
      eq_model2 = FactoryGirl.create(:equipment_model,
                                     category: category,
                                     ordering: 2)
      expect(OrderingHelper.new(eq_model1).predecessor).to eq(eq_model2)
    end
  end
  describe 'up' do
    it 'does not go past the first' do
      category = FactoryGirl.build(:category)
      eq_model1 = FactoryGirl.build(:equipment_model, category: category)
      eq_model2 = FactoryGirl.build(:equipment_model,
                                    category: category,
                                    ordering: 2)
      eq_model3 = FactoryGirl.build(:equipment_model,
                                    category: category,
                                    ordering: 3)
      OrderingHelper.new(eq_model1).up
      expect(eq_model1.ordering).to eq(1)
      expect(eq_model2.ordering).to eq(2)
      expect(eq_model3.ordering).to eq(3)
    end
    it 'pivots up and leaves neutral elements' do
      category = FactoryGirl.build(:category)
      eq_model1 = FactoryGirl.build_stubbed(:equipment_model,
                                            category: category)
      eq_model2 = FactoryGirl.build_stubbed(:equipment_model,
                                            category: category,
                                            ordering: 2)
      eq_model3 = FactoryGirl.build_stubbed(:equipment_model,
                                            category: category,
                                            ordering: 3)

      allow(eq_model1).to receive(:update_attribute)
      allow(eq_model2).to receive(:update_attribute)
      allow(eq_model3).to receive(:update_attribute)

      helper = OrderingHelper.new(eq_model3)
      allow(helper).to receive(:successor).and_return(eq_model2)
      helper.up
      expect(eq_model1).not_to have_received(:update_attribute)
      expect(eq_model2).to have_received(:update_attribute)
      expect(eq_model3).to have_received(:update_attribute)
    end
  end
  describe 'down' do
    it 'does not go past the last' do
      category = FactoryGirl.build(:category)
      eq_model1 = FactoryGirl.build(:equipment_model, category: category)
      eq_model2 = FactoryGirl.build(:equipment_model,
                                    category: category,
                                    ordering: 2)
      eq_model3 = FactoryGirl.build(:equipment_model,
                                    category: category,
                                    ordering: 3)

      OrderingHelper.new(eq_model3).down
      expect(eq_model1.ordering).to eq(1)
      expect(eq_model2.ordering).to eq(2)
      expect(eq_model3.ordering).to eq(3)
    end
    it 'pivots down and leaves neutral elements' do
      category = FactoryGirl.build(:category)
      eq_model1 = FactoryGirl.build_stubbed(:equipment_model,
                                            category: category)
      eq_model2 = FactoryGirl.build_stubbed(:equipment_model,
                                            category: category,
                                            ordering: 2)
      eq_model3 = FactoryGirl.build_stubbed(:equipment_model,
                                            category: category,
                                            ordering: 3)
      allow(eq_model1).to receive(:update_attribute)
      allow(eq_model2).to receive(:update_attribute)
      allow(eq_model3).to receive(:update_attribute)

      helper = OrderingHelper.new(eq_model1)
      allow(helper).to receive(:category_count).and_return(3)
      allow(helper).to receive(:predecessor).and_return(eq_model2)
      helper.down
      expect(eq_model1).to have_received(:update_attribute)
      expect(eq_model2).to have_received(:update_attribute)
      expect(eq_model3).not_to have_received(:update_attribute)
    end
  end
  describe 'deactivate' do
    it 'identifies successors' do
      category = FactoryGirl.create(:category)
      FactoryGirl.create(:equipment_model,
                         category: category,
                         ordering: 1)
      eq_model2 = FactoryGirl.create(:equipment_model,
                                     category: category,
                                     ordering: 2)
      eq_model3 = FactoryGirl.create(:equipment_model,
                                     category: category,
                                     ordering: 3)
      expect(OrderingHelper.new(eq_model2).successors).to eq([eq_model3])
    end
    it 'handles ordering on deactivation' do
      category = FactoryGirl.build(:category)
      eq_model1 = FactoryGirl.build_stubbed(:equipment_model,
                                            category: category)
      eq_model2 = FactoryGirl.build_stubbed(:equipment_model,
                                            category: category,
                                            ordering: 2)
      eq_model3 = FactoryGirl.build_stubbed(:equipment_model,
                                            category: category,
                                            ordering: 3)
      allow(eq_model1).to receive(:update_attribute)
      allow(eq_model2).to receive(:update_attribute)
      allow(eq_model2).to receive(:deactivate)
      allow(eq_model3).to receive(:update_attribute)
      helper = OrderingHelper.new(eq_model2)
      allow(helper).to receive(:successors).and_return([eq_model3])
      helper.deactivate_order
      expect(eq_model1).not_to have_received(:update_attribute)
      expect(eq_model2).to have_received(:update_attribute)
      expect(eq_model3).to have_received(:update_attribute)
    end
  end
end
