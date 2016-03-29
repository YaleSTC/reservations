# frozen_string_literal: true
require 'spec_helper'

def stub_ordering_helper(helper:, ordering:, successor:, predecessor:)
  allow(helper).to receive(:ordering).and_return(ordering)
  allow(helper).to receive(:predecessor).and_return(predecessor[:model])
  allow(helper).to receive(:successor).and_return(successor[:model])
  allow(helper).to receive(:successors).and_return([successor[:model]])
  allow(helper).to receive(:category_orderings)
    .and_return([predecessor[:ordering], ordering, successor[:ordering]])
end

def stubbed_eq_model(ord: nil)
  eq_model = FactoryGirl.build_stubbed(:equipment_model, ordering: ord)
  allow(eq_model).to receive(:update_attribute)
  eq_model
end

describe OrderingHelper do
  describe 'category information' do
    it 'finds cat_first and cat_last' do
      helper = OrderingHelper.new(stubbed_eq_model)
      allow(helper).to receive(:category_orderings).and_return([2, 5, 9])
      expect(helper.instance_eval { cat_last }).to eq(9)
      expect(helper.instance_eval { cat_first }).to eq(2)
    end
  end
  describe 'successor and predecessor' do
    before do
      @category = FactoryGirl.create(:category, id: 1)
      @category2 = FactoryGirl.create(:category, id: 2)
      @eq_model1 = FactoryGirl.create(:equipment_model,
                                      category: @category,
                                      ordering: 2)
      @eq_model2 = FactoryGirl.create(:equipment_model,
                                      category: @category,
                                      ordering: 4)
      @eq_model3 = FactoryGirl.create(:equipment_model,
                                      category: @category2,
                                      ordering: 3)
    end
    it 'yields the successor correctly' do
      helper = OrderingHelper.new(@eq_model1)
      expect(helper.instance_eval { successor }).to eq(@eq_model2)
    end
    it 'yields the predecessor correctly' do
      helper = OrderingHelper.new(@eq_model2)
      expect(helper.instance_eval { predecessor }).to eq(@eq_model1)
    end
  end
  describe 'up' do
    it 'does not go past the first' do
      eq_model = stubbed_eq_model(ord: 2)
      helper = OrderingHelper.new(eq_model)
      allow(helper).to receive(:cat_first).and_return(2)
      helper.up
      expect(eq_model).not_to have_received(:update_attribute)
    end
    it 'pivots up and leaves neutral elements' do
      eq_model1 = stubbed_eq_model
      eq_model2 = stubbed_eq_model
      eq_model3 = stubbed_eq_model
      helper = OrderingHelper.new(eq_model2)
      stub_ordering_helper(helper: helper, ordering: 3,
                           predecessor: { model: eq_model1, ordering: 1 },
                           successor: { model: eq_model3, ordering: 5 })

      helper.up

      expect(eq_model1).to have_received(:update_attribute).with('ordering', 3)
      expect(eq_model2).to have_received(:update_attribute).with('ordering', 1)
      expect(eq_model3).not_to have_received(:update_attribute)
    end
  end
  describe 'down' do
    it 'does not go past the last' do
      eq_model = stubbed_eq_model(ord: 2)
      helper = OrderingHelper.new(eq_model)
      allow(helper).to receive(:cat_last).and_return(2)
      helper.down
      expect(eq_model).not_to have_received(:update_attribute)
    end
    it 'pivots down and leaves neutral elements' do
      eq_model1 = stubbed_eq_model
      eq_model2 = stubbed_eq_model
      eq_model3 = stubbed_eq_model
      helper = OrderingHelper.new(eq_model2)
      stub_ordering_helper(helper: helper, ordering: 3,
                           predecessor: { model: eq_model1, ordering: 1 },
                           successor: { model: eq_model3, ordering: 5 })

      helper.down

      expect(eq_model1).not_to have_received(:update_attribute)
      expect(eq_model2).to have_received(:update_attribute).with('ordering', 5)
      expect(eq_model3).to have_received(:update_attribute).with('ordering', 3)
    end
  end
  describe 'deactivate' do
    it 'identifies successors' do
      FactoryGirl.create(:equipment_model,
                         ordering: 1)
      eq_model2 = FactoryGirl.create(:equipment_model,
                                     ordering: 3)
      eq_model3 = FactoryGirl.create(:equipment_model,
                                     ordering: 5)
      helper = OrderingHelper.new(eq_model2)
      expect(helper.instance_eval { successors }).to eq([eq_model3])
    end
    it 'handles ordering on deactivation' do
      eq_model1 = stubbed_eq_model(ord: 1)
      eq_model2 = stubbed_eq_model(ord: 3)
      eq_model3 = stubbed_eq_model(ord: 5)
      helper = OrderingHelper.new(eq_model2)
      stub_ordering_helper(helper: helper, ordering: 3,
                           predecessor: { model: eq_model1, ordering: 1 },
                           successor: { model: eq_model3, ordering: 5 })

      helper.deactivate_order

      expect(eq_model1).not_to have_received(:update_attribute)
      expect(eq_model2).to have_received(:update_attribute).with('ordering', 5)
      expect(eq_model3).to have_received(:update_attribute).with('ordering', 3)
    end
  end
end
