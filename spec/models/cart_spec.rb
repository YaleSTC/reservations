require 'spec_helper'

describe Cart do
  context "General validations" do
    it { should validate_presence_of(:reserver_id) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:due_date) }
  end

  let (:cart) { FactoryGirl.build(:cart) } # per http://betterspecs.org/#let
  it "has a working factory" do
    cart.should be_valid
  end

  describe ".initialize" do
    it "has no items" do
      cart.items.nil?
    end
    it "starts today " do
      cart.start_date == Date.today
    end
    it "is due tomorrow" do
      cart.due_date == Date.tomorrow
    end
    it "has no reserver" do
      cart.reserver_id.nil?
    end
    it "has errors" do
      cart.errors.count > 0
    end
  end

  describe ".persisted?" do
    it { cart.persisted?.should be_false }
  end

  ### TODO: Error-handling functions

  ### Item handling

  describe ".add_item" do
    let (:equipment_model) { FactoryGirl.build(:equipment_model) }
    it "adds an item" do
      lambda {
        cart.add_item(equipment_model)
      }.should change(cart.items, :count).by(1)
    end
  end

  describe ".remove_item" do
    # let (:equipment_model) { FactoryGirl.build(:equipment_model) }
    # let (:equipment_model_2) { FactoryGirl.build(:equipment_model) }

    before(:each) do
      @equipment_model = FactoryGirl.build(:equipment_model)
      @equipment_model_2 = FactoryGirl.build(:equipment_model)
      cart.add_item(@equipment_model)
      cart.add_item(@equipment_model_2)
    end

    it "removes an item" do
      lambda {
        cart.remove_item(@equipment_model)
      }.should change(cart.items, :count).by(-1)
    end

    it "removes the right model" # do
    #       lambda {
    #         cart.remove_item(equipment_model_2)
    #       }.should change(cart.items.each(&:equipment_model).select(|k,v| v == equipment_model_2) ).by(-1)
    #     end

    it "does not remove another model" # do
    #       lambda {
    #         cart.remove_item(equipment_model_2)
    #       }.should_not change(cart.items.each(&:equipment_model).select(|k,v| v == equipment_model) ).by(-1)
    #     end
  end

  describe ".cart_reservations" do
    it "finds items"
  end

  describe ".models_with_quantities" do
    it "returns a hash"
    it "gets the correct count of models"
  end

  describe ".empty?" do
    it "is true when there are no items in cart"
    it "is false when there are some items in cart"
  end

  describe ".set_start_date" do
    it "does not set a past date"
    # it "sets due date as start_date + 1 if due date precedes start date"
    # it "does not affect due date if unnecessary"
    it "sets new start and due dates for all items in cart"
  end

  describe ".set_due_date" do
    # it "sets due date as start_date + 1 if due date precedes start date"
    # it "does not affect due date if unnecessary"
    it "sets new due dates for all items in cart"
  end

  # If broken, then .set_due_date and .set_start_date are broken
  describe ".fix_due_date" do
    it "sets due date as start_date + 1 if due date precedes start date"
    it "does not affect due date if unnecessary"
  end

  describe ".renewable_reservation" do # TODO: Figure out
  end

  describe ".duration" do
    it "should give the right result"
  end
end