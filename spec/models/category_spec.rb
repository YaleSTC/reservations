require 'spec_helper'

describe Category do
  before(:each) do
    @category = FactoryGirl.build(:category)
  end

  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name) }

  it { should have_many(:equipment_models) }

  # validate numericality for :max_renewal_length, :max_renewal_times, :renewal_days_before_due, :max_per_user, :sort_order, :max_checkout_length
  # this includes integer_only, and greater_than_or_equal_to => 0

  # :max_renewal_length
  it "validates max_renewal_length must be non-negative" do
    @category.max_renewal_length = -1
    @category.save.should be_falsey
    @category.max_renewal_length = 0
    @category.save.should be_truthy
  end
  it "validates max_renewal_length can be nil" do
    @category.max_renewal_length = nil
    @category.save.should be_truthy
  end
  it "validates max_renewal_length must be an integer" do
    @category.max_renewal_length = "not_an_integer"
    @category.save.should be_falsey
    @category.max_renewal_length = 1
    @category.save.should be_truthy
  end

  # :max_renewal_times
  it "validates max_renewal_times must be non-negative" do
    @category.max_renewal_times = -1
    @category.save.should be_falsey
    @category.max_renewal_times = 0
    @category.save.should be_truthy
  end
  it "validates max_renewal_times can be nil" do
    @category.max_renewal_times = nil
    @category.save.should be_truthy
  end
  it "validates max_renewal_times must be an integer" do
    @category.max_renewal_times = "not_an_integer"
    @category.save.should be_falsey
    @category.max_renewal_times = 1
    @category.save.should be_truthy
  end

  # :renewal_days_before_due
  it "validates renewal_days_before_due must be non-negative" do
    @category.renewal_days_before_due = -1
    @category.save.should be_falsey
    @category.renewal_days_before_due = 0
    @category.save.should be_truthy
  end
  it "validates renewal_days_before_due can be nil" do
    @category.renewal_days_before_due = nil
    @category.save.should be_truthy
  end
  it "validates renewal_days_before_due must be an integer" do
    @category.renewal_days_before_due = "not_an_integer"
    @category.save.should be_falsey
    @category.renewal_days_before_due = 1
    @category.save.should be_truthy
  end

  # :sort_order
  it "validates sort_order must be non-negative" do
    @category.sort_order = -1
    @category.save.should be_falsey
    @category.sort_order = 0
    @category.save.should be_truthy
  end
  it "validates sort_order can be nil" do
    @category.sort_order = nil
    @category.save.should be_truthy
  end
  it "validates sort_order must be an integer" do
    @category.sort_order = "not_an_integer"
    @category.save.should be_falsey
    @category.sort_order = 1
    @category.save.should be_truthy
  end

  # :max_per_user
  it "validates max_per_user must be non-negative" do
    @category.max_per_user = -1
    @category.save.should be_falsey
    @category.max_per_user = 0
    @category.save.should be_truthy
  end
  it "validates max_per_user can be nil" do
    @category.max_per_user = nil
    @category.save.should be_truthy
  end
  it "validates max_per_user must be an integer" do
    @category.max_per_user = "not_an_integer"
    @category.save.should be_falsey
    @category.max_per_user = 1
    @category.save.should be_truthy
  end

  # :max_checkout_length
  it "validates max_checkout_length must be non-negative" do
    @category.max_checkout_length = -1
    @category.save.should be_falsey
    @category.max_checkout_length = 0
    @category.save.should be_truthy
  end
  it "validates max_checkout_length can be nil" do
    @category.max_checkout_length = nil
    @category.save.should be_truthy
  end
  it "validates max_checkout_length must be an integer" do
    @category.max_checkout_length = "not_an_integer"
    @category.save.should be_falsey
    @category.max_checkout_length = 1
    @category.save.should be_truthy
  end

  # custom scope to return active categories
  describe ".active" do
    before(:each) do
      @deactivated = FactoryGirl.create(:category, deleted_at: "2013-01-01 00:00:00" )
      @category.save
    end

    it "Should return all active categories" do
      Category.active.should include(@category)
    end

    it "Should not return inactive categories" do
      Category.active.should_not include(@deactivated)
    end
  end

  describe "#maximum_per_user" do
    before(:each) do
      @category.max_per_user = 1
      @category.save
      @unrestrected_category = FactoryGirl.create(:category, max_per_user: nil)
    end
    it "Should return maximum_per_user if defined" do
      @category.maximum_per_user.should == 1
    end
    it "Should return 'unrestricted' if not defined" do
      @unrestrected_category.maximum_per_user.should == 'unrestricted'
    end
  end

  describe "#maximum_renewal_length" do
    before(:each) do
      @category.max_renewal_length = 5
      @category.save
      @unrestrected_category = FactoryGirl.create(:category, max_renewal_length: nil)
    end
    it "Should return maximum_renewal_length if defined" do
      @category.maximum_renewal_length.should == 5
    end
    it "Default to 0 if not defined" do
      @unrestrected_category.maximum_renewal_length.should == 0
    end
  end

  describe "#maximum_renewal_times" do
    before(:each) do
      @category.max_renewal_times = 1
      @category.save
      @unrestrected_category = FactoryGirl.create(:category, max_renewal_times: nil)
    end
    it "Should return maximum_renewal_times if defined" do
      @category.maximum_renewal_times.should == 1
    end
    it "Default to unrestricted if not defined" do
      @unrestrected_category.maximum_renewal_times.should == 'unrestricted'
    end
  end

  describe "#maximum_renewal_days_before_due" do
    before(:each) do
      @category.renewal_days_before_due = 1
      @category.save
      @unrestrected_category = FactoryGirl.create(:category, renewal_days_before_due: nil)
    end
    it "Should return maximum_renewal_days_before_due if defined" do
      @category.maximum_renewal_days_before_due.should == 1
    end
    it "Default to unrestricted if not defined" do
      @unrestrected_category.maximum_renewal_days_before_due.should == 'unrestricted'
    end
  end

  describe "#maximum_checkout_length" do
    before(:each) do
      @category.max_checkout_length = 5
      @category.save
      @unrestrected_category = FactoryGirl.create(:category, max_checkout_length: nil)
    end
    it "Should return maximum_checkout_length if defined" do
      @category.maximum_checkout_length.should == 5
    end
    it "Default to unrestricted if not defined" do
      @unrestrected_category.maximum_checkout_length.should == 'unrestricted'
    end
  end

  describe ".catalog_search" do
    before(:each) do
      @category.name = "Tumblr hipster instagram sustainable"
      @category.save
      @hipster = FactoryGirl.create(:category, name: "Tumblr starbucks PBR slackline music hipster")
    end
    it "Should return names matching all of the query words" do
      Category.catalog_search("Tumblr").should == [@category, @hipster]
      Category.catalog_search("Tumblr hipster").should == [@category, @hipster]
    end
    it "Should not return any categories without every query word in the name" do
      Category.catalog_search("starbucks").should == [@hipster]
      Category.catalog_search("Tumblr instagram sustainable").should == [@category]
    end
  end
end
