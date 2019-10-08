# frozen_string_literal: true

require 'spec_helper'

describe Category, type: :model do
  it_behaves_like 'soft deletable'

  before(:each) do
    @category = FactoryGirl.build(:category)
  end

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name).case_insensitive }

  it { is_expected.to have_many(:equipment_models) }

  # validate numericality for :max_renewal_length, :max_renewal_times,
  # :renewal_days_before_due, :max_per_user, :sort_order, :max_checkout_length
  # this includes integer_only, and greater_than_or_equal_to => 0

  # :max_renewal_length
  it 'validates max_renewal_length must be non-negative' do
    @category.max_renewal_length = -1
    expect(@category.save).to be_falsey
    @category.max_renewal_length = 0
    expect(@category.save).to be_truthy
  end
  it 'validates max_renewal_length can be nil' do
    @category.max_renewal_length = nil
    expect(@category.save).to be_truthy
  end
  it 'validates max_renewal_length must be an integer' do
    @category.max_renewal_length = 'not_an_integer'
    expect(@category.save).to be_falsey
    @category.max_renewal_length = 1
    expect(@category.save).to be_truthy
  end

  # :max_renewal_times
  it 'validates max_renewal_times must be non-negative' do
    @category.max_renewal_times = -1
    expect(@category.save).to be_falsey
    @category.max_renewal_times = 0
    expect(@category.save).to be_truthy
  end
  it 'validates max_renewal_times can be nil' do
    @category.max_renewal_times = nil
    expect(@category.save).to be_truthy
  end
  it 'validates max_renewal_times must be an integer' do
    @category.max_renewal_times = 'not_an_integer'
    expect(@category.save).to be_falsey
    @category.max_renewal_times = 1
    expect(@category.save).to be_truthy
  end

  # :renewal_days_before_due
  it 'validates renewal_days_before_due must be non-negative' do
    @category.renewal_days_before_due = -1
    expect(@category.save).to be_falsey
    @category.renewal_days_before_due = 0
    expect(@category.save).to be_truthy
  end
  it 'validates renewal_days_before_due can be nil' do
    @category.renewal_days_before_due = nil
    expect(@category.save).to be_truthy
  end
  it 'validates renewal_days_before_due must be an integer' do
    @category.renewal_days_before_due = 'not_an_integer'
    expect(@category.save).to be_falsey
    @category.renewal_days_before_due = 1
    expect(@category.save).to be_truthy
  end

  # :sort_order
  it 'validates sort_order must be non-negative' do
    @category.sort_order = -1
    expect(@category.save).to be_falsey
    @category.sort_order = 0
    expect(@category.save).to be_truthy
  end
  it 'validates sort_order can be nil' do
    @category.sort_order = nil
    expect(@category.save).to be_truthy
  end
  it 'validates sort_order must be an integer' do
    @category.sort_order = 'not_an_integer'
    expect(@category.save).to be_falsey
    @category.sort_order = 1
    expect(@category.save).to be_truthy
  end

  # :max_per_user
  it 'validates max_per_user must be non-negative' do
    @category.max_per_user = -1
    expect(@category.save).to be_falsey
    @category.max_per_user = 0
    expect(@category.save).to be_truthy
  end
  it 'validates max_per_user can be nil' do
    @category.max_per_user = nil
    expect(@category.save).to be_truthy
  end
  it 'validates max_per_user must be an integer' do
    @category.max_per_user = 'not_an_integer'
    expect(@category.save).to be_falsey
    @category.max_per_user = 1
    expect(@category.save).to be_truthy
  end

  # :max_checkout_length
  it 'validates max_checkout_length must be non-negative' do
    @category.max_checkout_length = -1
    expect(@category.save).to be_falsey
    @category.max_checkout_length = 0
    expect(@category.save).to be_truthy
  end
  it 'validates max_checkout_length can be nil' do
    @category.max_checkout_length = nil
    expect(@category.save).to be_truthy
  end
  it 'validates max_checkout_length must be an integer' do
    @category.max_checkout_length = 'not_an_integer'
    expect(@category.save).to be_falsey
    @category.max_checkout_length = 1
    expect(@category.save).to be_truthy
  end

  # custom scope to return active categories
  describe '.active' do
    before(:each) do
      @deactivated = FactoryGirl.create(:category,
                                        deleted_at: '2013-01-01 00:00:00')
      @category.save
    end

    it 'Should return all active categories' do
      expect(Category.active).to include(@category)
    end

    it 'Should not return inactive categories' do
      expect(Category.active).not_to include(@deactivated)
    end
  end

  describe '#maximum_per_user' do
    before(:each) do
      @category.max_per_user = 1
      @category.save
      @unrestrected_category = FactoryGirl.create(:category,
                                                  max_per_user: nil)
    end
    it 'Should return maximum_per_user if defined' do
      expect(@category.maximum_per_user).to eq(1)
    end
    it 'Should return Float::INFINITY if not defined' do
      expect(@unrestrected_category.maximum_per_user).to eq(Float::INFINITY)
    end
  end

  describe '#maximum_renewal_length' do
    before(:each) do
      @category.max_renewal_length = 5
      @category.save
      @unrestrected_category = FactoryGirl.create(:category,
                                                  max_renewal_length: nil)
    end
    it 'Should return maximum_renewal_length if defined' do
      expect(@category.maximum_renewal_length).to eq(5)
    end
    it 'Default to 0 if not defined' do
      expect(@unrestrected_category.maximum_renewal_length).to eq(0)
    end
  end

  describe '#maximum_renewal_times' do
    before(:each) do
      @category.max_renewal_times = 1
      @category.save
      @unrestrected_category = FactoryGirl.create(:category,
                                                  max_renewal_times: nil)
    end
    it 'Should return maximum_renewal_times if defined' do
      expect(@category.maximum_renewal_times).to eq(1)
    end
    it 'Default to infinity if not defined' do
      expect(@unrestrected_category.maximum_renewal_times).to\
        eq(Float::INFINITY)
    end
  end

  describe '#maximum_renewal_days_before_due' do
    before(:each) do
      @category.renewal_days_before_due = 1
      @category.save
      @unrestrected_category = FactoryGirl.create(:category,
                                                  renewal_days_before_due: nil)
    end
    it 'Should return maximum_renewal_days_before_due if defined' do
      expect(@category.maximum_renewal_days_before_due).to eq(1)
    end
    it 'Default to infinity if not defined' do
      expect(@unrestrected_category.maximum_renewal_days_before_due).to\
        eq(Float::INFINITY)
    end
  end

  describe '#maximum_checkout_length' do
    before(:each) do
      @category.max_checkout_length = 5
      @category.save
      @unrestrected_category = FactoryGirl.create(:category,
                                                  max_checkout_length: nil)
    end
    it 'Should return maximum_checkout_length if defined' do
      expect(@category.maximum_checkout_length).to eq(5)
    end
    it 'Default to infinity if not defined' do
      expect(@unrestrected_category.maximum_checkout_length).to\
        eq(Float::INFINITY)
    end
  end

  describe '.catalog_search' do
    before(:each) do
      @category.name = 'Tumblr hipster instagram sustainable'
      @category.save
      @hipster =
        FactoryGirl.create(:category,
                           name: 'Tumblr starbucks PBR slackline music hipster')
    end
    it 'Should return names matching all of the query words' do
      expect(Category.catalog_search('Tumblr')).to eq([@category, @hipster])
      expect(Category.catalog_search('Tumblr hipster')).to\
        eq([@category, @hipster])
    end
    it 'Should not return any categories without every query word in the '\
      'name' do
      expect(Category.catalog_search('starbucks')).to eq([@hipster])
      expect(Category.catalog_search('Tumblr instagram sustainable')).to\
        eq([@category])
    end
  end
end
