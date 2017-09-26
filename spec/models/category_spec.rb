# frozen_string_literal: true
require 'spec_helper'

describe Category, type: :model do
  describe 'basic validations' do
    subject(:category) { FactoryGirl.build(:category) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to have_many(:equipment_models) }
  end

  shared_examples 'integer attribute' do |attr|
    it "is valid when #{attr} is an integer >= 0" do
      category = FactoryGirl.build_stubbed(:category, attr => 0)
      expect(category.valid?).to be_truthy
    end
    it "is valid when #{attr} is nil" do
      category = FactoryGirl.build_stubbed(:category, attr => nil)
      expect(category.valid?).to be_truthy
    end
    it "is invalid when #{attr} is not an integer" do
      category = FactoryGirl.build_stubbed(:category, attr => 'not an int')
      expect(category.valid?).to be_falsey
    end
    it "is invalid when #{attr} is < 0 " do
      category = FactoryGirl.build_stubbed(:category, attr => -1)
      expect(category.valid?).to be_falsey
    end
  end
  it_behaves_like 'integer attribute', :max_renewal_length
  it_behaves_like 'integer attribute', :max_renewal_times
  it_behaves_like 'integer attribute', :renewal_days_before_due
  it_behaves_like 'integer attribute', :sort_order
  it_behaves_like 'integer attribute', :max_per_user
  it_behaves_like 'integer attribute', :max_checkout_length

  shared_examples 'attribute methods' do |attr, method, default|
    it "#{method} returns #{attr} when defined" do
      category = FactoryGirl.build_stubbed(:category, attr => 1)
      expect(category.send(method)).to eq(1)
    end
    it "#{method} returns appropriate default when #{attr} is not defined" do
      category = FactoryGirl.build_stubbed(:category, attr => nil)
      expect(category.send(method)).to eq(default)
    end
  end
  it_behaves_like 'attribute methods', :max_renewal_length,
                  :maximum_renewal_length, 0
  it_behaves_like 'attribute methods', :max_renewal_times,
                  :maximum_renewal_times, Float::INFINITY
  it_behaves_like 'attribute methods', :renewal_days_before_due,
                  :maximum_renewal_days_before_due, Float::INFINITY
  it_behaves_like 'attribute methods', :max_per_user,
                  :maximum_per_user, Float::INFINITY
  it_behaves_like 'attribute methods', :max_checkout_length,
                  :maximum_checkout_length, Float::INFINITY

  describe '#active' do
    it 'returns active categories' do
      category = FactoryGirl.create(:category)
      expect(Category.active).to include(category)
    end
    it 'does not return inactive categories' do
      deactivated = FactoryGirl.create(:category,
                                       deleted_at: '2013-01-01 00:00:00')
      expect(Category.active).not_to include(deactivated)
    end
  end

  describe 'catalog_search' do
    let!(:category) do
      FactoryGirl.create(:category,
                         name: 'Tumblr hipster instagram sustainable')
    end
    let!(:hipster) do
      FactoryGirl.create(:category,
                         name: 'Tumblr starbucks PBR slackline music hipster')
    end
    it 'Should return names matching all of the query words' do
      expect(Category.catalog_search('Tumblr')).to eq([category, hipster])
      expect(Category.catalog_search('Tumblr hipster')).to\
        eq([category, hipster])
    end
    it 'Should not return any categories without every query word in the '\
      'name' do
      expect(Category.catalog_search('starbucks')).to eq([hipster])
      expect(Category.catalog_search('Tumblr instagram sustainable')).to\
        eq([category])
    end
  end
end
