require 'spec_helper'

describe EquipmentModel do
  context "basic validations" do
    before(:each) do
      @model = FactoryGirl.build(:equipment_model)
    end

    it "has a working factory" do
      @model.save.should be_true
    end

    it "requires a name" do
      @model.name = ""
      @model.save.should be_false
      @model.name = "Model"
      @model.save.should be_true
    end

    it "requires a description" do
      @model.description = ""
      @model.save.should be_false
      @model.description = "This is a model."
      @model.save.should be_true
    end

    it "requires an associated category" do
      @model.category = nil
      @model.save.should be_false
      @model.category = FactoryGirl.create(:microphone)
      @model.save.should be_true
    end

    # I don't like having to assign this to a different category, but I can't figure out how to
    # use factories to generate one category and assign multiple models to it.
    it "requires a unique name" do
      @identical_model = FactoryGirl.build(:equipment_model, category: FactoryGirl.create(:microphone), name: "Model")
      @model.save
      @identical_model.save.should be_false
    end

    it "requires a late fee greater than or equal to 0" do
      @model.late_fee = "-1.00"
      @model.save.should be_false
      @model.late_fee = "0.00"
      @model.save.should be_true
    end

    it "requires a replacement fee greater than or equal to 0" do
      @model.replacement_fee = "-1.00"
      @model.save.should be_false
      @model.replacement_fee = "0.00"
      @model.save.should be_true
    end

    # max_per_user
    # note: for some reason this allows a max_per_user value of "2.3" as a string to save properly.
    it "requires an integer value for maximum per user" do
      @model.max_per_user = 2.3
      @model.save.should be_false
      @model.max_per_user = 2
      @model.save.should be_true
    end
    it "requires a maximum per user value greater than or equal to 1" do
      @model.max_per_user = -1
      @model.save.should be_false
      @model.max_per_user = 0
      @model.save.should be_false
      @model.max_per_user = 1
      @model.save.should be_true
    end
    # only necessary because of integer requirement
    it "allows nil values for maximum per user" do
      @model.max_per_user = nil
      @model.save.should be_true
    end

    # max_renewal_length
    it "requires an integer value for maximum renewal length" do
      @model.max_renewal_length = 2.3
      @model.save.should be_false
      @model.max_renewal_length = 2
      @model.save.should be_true
    end
    it "requires a maximum renewal length value greater than or equal to 0" do
      @model.max_renewal_length = -1
      @model.save.should be_false
      @model.max_renewal_length = 0
      @model.save.should be_true
    end
    it "allows nil values for maximum renewal length" do
      @model.max_renewal_length = nil
      @model.save.should be_true
    end

    # max_renewal_times
    it "requires an integer value for maximum renewal times" do
      @model.max_renewal_times = 2.3
      @model.save.should be_false
      @model.max_renewal_times = 2
      @model.save.should be_true
    end
    it "requires a maximum renewal times value greater than or equal to 0" do
      @model.max_renewal_times = -1
      @model.save.should be_false
      @model.max_renewal_times = 0
      @model.save.should be_true
    end
    it "allows nil values for maximum renewal times" do
      @model.max_renewal_times = nil
      @model.save.should be_true
    end

    # renewal_days_before_due
    it "requires an integer value for renewal days before due" do
      @model.renewal_days_before_due = 2.3
      @model.save.should be_false
      @model.renewal_days_before_due = 2
      @model.save.should be_true
    end
    it "requires a renewal days before due value greater than or equal to 0" do
      @model.renewal_days_before_due = -1
      @model.save.should be_false
      @model.renewal_days_before_due = 0
      @model.save.should be_true
    end
    it "allows nil values for renewal days before due" do
      @model.renewal_days_before_due = nil
      @model.save.should be_true
    end
  end

  context "association validations" do
    before(:each) do
      @model_with_accessory = FactoryGirl.build(:model_with_accessory)
    end
    it "has a working association callback" do
      @model_with_accessory.save.should be_true
    end
    it "does not permit association with itself" do
      @model_with_accessory.associated_equipment_model_ids = [4]
      @model_with_accessory.save.should be_false
      @model_with_accessory.associated_equipment_model_ids = [3]
      @model_with_accessory.save.should be_true
    end
    describe ".not_associated_with_self" do
      it "creates an error if associated with self" do
        @model_with_accessory.associated_equipment_model_ids = [4]
        @associated_with_self = @model_with_accessory
        @associated_with_self.not_associated_with_self
        @associated_with_self.errors.first.should be_true
      end
    end
  end

  context "class methods" do
    describe "#catalog_search" do
      before(:each) do
        @model = FactoryGirl.create(:equipment_model, name: "Tumblr hipster woodstock PBR messenger bag",
                                                      description: "You probably haven't heard of them jean shorts. Raw \
                                                                    denim you probably haven't heard of them vegan \
                                                                    8-bit occupy mustache four loko." )
        @another_model = FactoryGirl.create(:another_equipment_model, name: "Tumblr hipster starbucks alternative music",
                                                                      description: "Craft beer sartorial four loko blog jean \
                                                                                    shorts chillwave aesthetic. Roof party art party banh \
                                                                                    mi aesthetic, ennui Marfa kitsch readymade vegan food truck bag." )
      end
      it "Should return equipment_models with all of the query words in either name or description" do
        EquipmentModel.catalog_search("Tumblr").should == [@model, @another_model]
        EquipmentModel.catalog_search("Tumblr hipster").should == [@model, @another_model]
        EquipmentModel.catalog_search("Tumblr bag").should == [@model, @another_model]
        EquipmentModel.catalog_search("jean shorts vegan").should == [@model, @another_model]
      end
      it "Should not return any equipment_models without every query word in the name or description" do
        EquipmentModel.catalog_search("starbucks").should == [@another_model]
        EquipmentModel.catalog_search("Tumblr hipster woodstock PBR").should == [@model]
        EquipmentModel.catalog_search("Craft beer sartorial four loko").should == [@another_model]
      end
    end
    describe "#select_options" do
      # This method currently exists but appears to be dead code -- verify and remove.
    end
  end

  context "instance methods", focus: true do
    before(:each) do
      @model = FactoryGirl.create(:equipment_model)
    end
    describe ".maximum_per_user" do
      it "should return the max_per_user if specified" do
        @model.maximum_per_user.should == 10
      end
      it "should return the associated category's max_per_user if unspecified" do
        @model.max_per_user = nil
        @model.maximum_per_user.should == 1
      end
    end
    describe ".maximum_renewal_length" do
      it "should return the max_renewal_length if specified" do
        @model.maximum_renewal_length.should == 10
      end
      it "should return the associated category's max_renewal_length if unspecified" do
        @model.max_renewal_length = nil
        @model.maximum_renewal_length.should == 5
      end
    end
    describe ".maximum_renewal_times" do
      it "should return the max_renewal_times if specified" do
        @model.maximum_renewal_times.should == 10
      end
      it "should return the associated category's max_renewal_length if unspecified" do
        @model.max_renewal_times = nil
        @model.maximum_renewal_times.should == 1
      end
    end
    describe ".maximum_renewal_days_before_due" do
      it "should return the model's renewal_days_before_due if specified" do
        @model.maximum_renewal_days_before_due.should == 10
      end
      it "should return the associated category's renewal_days_before_due if unspecified" do
        @model.renewal_days_before_due = nil
        @model.maximum_renewal_days_before_due.should == 1
      end
    end

    describe ".document_attributes=" do
    end
    describe ".num_available"
    describe ".model_restricted?"
    describe ".number_reserved_on_date"
    describe ".number_overdue"
    describe ".available_count"
    describe ".available_object_select_options"
  end

  context "paperclip" do
    # not sure what this is/how it works, research and complete later.
  end
end
