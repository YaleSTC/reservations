require 'spec_helper'

describe EquipmentModel do
  context "basic validations" do
    before(:each) do
      @model = FactoryGirl.build(:equipment_model)
    end

    it "has a working factory" do
      @model.save.should be_truthy
    end

    it { should belong_to(:category) }
    it { should have_and_belong_to_many(:requirements) }
    it { should have_many(:equipment_objects) }

    #TODO: figure out how to implement this in order to create a passing test (the model currently works but the test fails)
    # it { should have_many(:documents) }

    it { should have_many(:reservations) }
    it { should have_many(:checkin_procedures) }
    it { should accept_nested_attributes_for(:checkin_procedures) }
    it { should have_many(:checkout_procedures) }
    it { should accept_nested_attributes_for(:checkout_procedures) }
    it { should have_and_belong_to_many(:associated_equipment_models) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:description) }

    it "requires an associated category" do
      @model.category = nil
      @model.save.should be_falsey
      @model.category = FactoryGirl.create(:category)
      @model.save.should be_truthy
    end

    it { should validate_uniqueness_of(:name) }

    it "requires a late fee greater than or equal to 0" do
      @model.late_fee = "-1.00"
      @model.save.should be_falsey
      @model.late_fee = "0.00"
      @model.save.should be_truthy
    end

    it "requires a replacement fee greater than or equal to 0" do
      @model.replacement_fee = "-1.00"
      @model.save.should be_falsey
      @model.replacement_fee = "0.00"
      @model.save.should be_truthy
    end

    # max_per_user
    # note: for some reason this allows a max_per_user value of "2.3" as a string to save properly.
    it "requires an integer value for maximum per user" do
      @model.max_per_user = 2.3
      @model.save.should be_falsey
      @model.max_per_user = 2
      @model.save.should be_truthy
    end
    it "requires a maximum per user value greater than or equal to 1" do
      @model.max_per_user = -1
      @model.save.should be_falsey
      @model.max_per_user = 0
      @model.save.should be_falsey
      @model.max_per_user = 1
      @model.save.should be_truthy
    end
    # only necessary because of integer requirement
    it "allows nil values for maximum per user" do
      @model.max_per_user = nil
      @model.save.should be_truthy
    end

    # max_renewal_length
    it "requires an integer value for maximum renewal length" do
      @model.max_renewal_length = 2.3
      @model.save.should be_falsey
      @model.max_renewal_length = 2
      @model.save.should be_truthy
    end
    it "requires a maximum renewal length value greater than or equal to 0" do
      @model.max_renewal_length = -1
      @model.save.should be_falsey
      @model.max_renewal_length = 0
      @model.save.should be_truthy
    end
    it "allows nil values for maximum renewal length" do
      @model.max_renewal_length = nil
      @model.save.should be_truthy
    end

    # max_renewal_times
    it "requires an integer value for maximum renewal times" do
      @model.max_renewal_times = 2.3
      @model.save.should be_falsey
      @model.max_renewal_times = 2
      @model.save.should be_truthy
    end
    it "requires a maximum renewal times value greater than or equal to 0" do
      @model.max_renewal_times = -1
      @model.save.should be_falsey
      @model.max_renewal_times = 0
      @model.save.should be_truthy
    end
    it "allows nil values for maximum renewal times" do
      @model.max_renewal_times = nil
      @model.save.should be_truthy
    end

    # renewal_days_before_due
    it "requires an integer value for renewal days before due" do
      @model.renewal_days_before_due = 2.3
      @model.save.should be_falsey
      @model.renewal_days_before_due = 2
      @model.save.should be_truthy
    end
    it "requires a renewal days before due value greater than or equal to 0" do
      @model.renewal_days_before_due = -1
      @model.save.should be_falsey
      @model.renewal_days_before_due = 0
      @model.save.should be_truthy
    end
    it "allows nil values for renewal days before due" do
      @model.renewal_days_before_due = nil
      @model.save.should be_truthy
    end
  end

  context "association validations" do
    before(:each) do
      @unique_id = FactoryGirl.generate(:unique_id)
      @model = FactoryGirl.create(:equipment_model, id: @unique_id)
    end
    it "has a working association callback" do
      @model.save.should be_truthy
    end
    it "does not permit association with itself" do
      @model.associated_equipment_model_ids = [@unique_id]
      @model.save.should be_falsey
    end
    describe ".not_associated_with_self" do
      it "creates an error if associated with self" do
        @model.associated_equipment_model_ids = [@unique_id]
        @model.not_associated_with_self
        @model.errors.first.should be_truthy
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
        @another_model = FactoryGirl.create(:equipment_model, name: "Tumblr hipster starbucks alternative music",
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

  context "instance methods" do
    before(:each) do
      @category = FactoryGirl.create(:category)
      @model = FactoryGirl.create(:equipment_model, category: @category)
    end
    describe ".maximum_per_user" do
      it "should return the max_per_user if specified" do
        @model.maximum_per_user.should == @model.max_per_user
      end
      it "should return the associated category's max_per_user if unspecified" do
        @model.max_per_user = nil
        @model.maximum_per_user.should == @category.maximum_per_user
      end
    end
    describe ".maximum_renewal_length" do
      it "should return the max_renewal_length if specified" do
        @model.maximum_renewal_length.should == @model.max_renewal_length
      end
      it "should return the associated category's max_renewal_length if unspecified" do
        @model.max_renewal_length = nil
        @model.maximum_renewal_length.should == @category.maximum_renewal_length
      end
    end
    describe ".maximum_renewal_times" do
      it "should return the max_renewal_times if specified" do
        @model.maximum_renewal_times.should == @model.max_renewal_times
      end
      it "should return the associated category's max_renewal_length if unspecified" do
        @model.max_renewal_times = nil
        @model.maximum_renewal_times.should == @category.maximum_renewal_times
      end
    end
    describe ".maximum_renewal_days_before_due" do
      it "should return the model's renewal_days_before_due if specified" do
        @model.maximum_renewal_days_before_due.should == @model.renewal_days_before_due
      end
      it "should return the associated category's renewal_days_before_due if unspecified" do
        @model.renewal_days_before_due = nil
        @model.maximum_renewal_days_before_due.should == @category.maximum_renewal_days_before_due
      end
    end

    describe ".document_attributes=" do
      #This method doesn't appear to do anything whatsoever
    end

    # TODO: Need requirements model and factory to build the environment for this test.
    describe ".model_restricted?" do
      before(:each) do
        @requirement = FactoryGirl.create(:requirement)
        @requirement2 = FactoryGirl.create(:requirement)
        @model = FactoryGirl.create(:equipment_model, requirements: [@requirement, @requirement2])
      end
      it "should return false if the user has fulfilled the requirements to use the model" do
        @user = FactoryGirl.create(:user, requirements: [@requirement, @requirement2])
        @model.model_restricted?(@user.id).should be_falsey
      end
      it "should return false if the model has no requirements" do
        @model.requirements = []
        @user = FactoryGirl.create(:user, requirements: [@requirement, @requirement2])
        @model.model_restricted?(@user.id).should be_falsey
      end
      it "should return true if the user has not fulfilled all of the requirements" do
        @user = FactoryGirl.create(:user, requirements: [@requirement])
        @model.model_restricted?(@user.id).should be_truthy
      end
      it "should return true if the user has not fulfilled any of the requirements" do
        @user = FactoryGirl.create(:user)
        @model.model_restricted?(@user.id).should be_truthy
      end
    end

    context "methods involving reservations" do
      # @model and @category are already set.
      describe ".num_available" do
        it "should return the number of objects of that model available over a given date range" do
          @reservation = FactoryGirl.create(:valid_reservation, equipment_model: @model)
          @extra_object = FactoryGirl.create(:equipment_object, equipment_model: @model)
          @model.equipment_objects.size.should eq(2)
          @model.num_available(@reservation.start_date, @reservation.due_date).should eq(1)
        end
        it "should return 0 if no objects of that model are available" do
          @reservation = FactoryGirl.create(:valid_reservation, equipment_model: @model)
          @model.num_available(@reservation.start_date, @reservation.due_date).should eq(0)
        end
      end
      describe ".number_overdue" do
        it "should return the number of objects of a given model that are checked out and overdue" do
          @reservation = FactoryGirl.build(:overdue_reservation, equipment_model: @model)
          @reservation.save(validate: false)
          @extra_object = FactoryGirl.create(:equipment_object, equipment_model: @model)
          @model.equipment_objects.size.should eq(2)
          @model.number_overdue.should eq(1)
        end
      end
      describe ".available_count" do
        it "should take the total # of the model, subtract the number reserved, checked-out, and overdue for the given date and return the result" do
          4.times do
            FactoryGirl.create(:equipment_object, equipment_model: @model)
          end
          FactoryGirl.create(:valid_reservation, equipment_model: @model)
          FactoryGirl.create(:checked_out_reservation, equipment_model: @model)
          @overdue = FactoryGirl.build(:overdue_reservation, equipment_model: @model)
          @overdue.save(validate: false)
          @model.equipment_objects.size.should eq(4)
          @model.available_count(Date.today).should eq(1)
        end
      end
      describe ".available_object_select_options" do
        it "should make a string listing the available objects" do
          @reservation = FactoryGirl.create(:checked_out_reservation, equipment_model: @model)
          @object = FactoryGirl.create(:equipment_object, equipment_model: @model)
          @model.available_object_select_options.should eq("<option value=#{@object.id}>#{@object.name}</option>")
        end
      end
    end
  end
  context "paperclip" do
    # not sure what this is/how it works, research and complete later.
  end
end
