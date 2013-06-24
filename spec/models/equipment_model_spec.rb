require 'spec_helper'

describe EquipmentModel do
  before(:each) do
    @model = FactoryGirl.build(:equipment_model)
  end

  it "has a working factory" do
    @model.save.should be_true
  end

  it "requires a name"
  it "requires a description"
  it "requires an associated category"
  it "requires a unique name"
  it "requires a late fee greater than or equal to 0"
  it "requires a replacement fee greater than or equal to 0"
  it "requires an integer value for maximum per user"
  it "requires a maximum per user value greater than or equal to 1"
  it "allows nil values for maximum per user"
  it "requires an integer value for maximum renewal length"
  it "requires a maximum renewal length value greater than or equal to 0"
  it "allows nil values for maximum renewal length"
  it "requires an integer value for maximum renewal times"
  it "requires a maximum renewal times value greater than or equal to 0"
  it "allows nil values for maximum renewal times"
  it "requires an integer value for renewal days before due"
  it "requires a renewal days before due value greater than or equal to 0"
  it "allows nil values for renewal days before due"
  it "does not permit association with itself"
end
