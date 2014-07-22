require 'spec_helper'

describe Cart do
  before (:each) do
    @cart = FactoryGirl.build(:cart)
    @cart.items = {} # Needed to avoid db flushing problems
  end

  it "has a working factory" do
    @cart.should be_valid
  end

  context "General validations" do
    it { should validate_presence_of(:reserver_id) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:due_date) }
  end

  describe ".initialize" do
    it "has no items" do
      @cart.items.nil?
    end
    it "starts today " do
      @cart.start_date == Date.current
    end
    it "is due tomorrow" do
      @cart.due_date == (Date.current+1.day)
    end
    it "has no reserver" do
      @cart.reserver_id.nil?
    end
    it "has errors" do
      @cart.errors.count > 0
    end
  end

  describe ".persisted?" do
    it { @cart.persisted?.should be_falsey }
  end

  describe "Item handling" do
    before (:each) do
      @equipment_model = FactoryGirl.create(:equipment_model)
    end

    describe ".add_item" do
      it "adds an item" do
        @cart.add_item(@equipment_model)
        expect(@cart.items).to include(@equipment_model.id)
      end
      it "increments if an item is already present" do
        @cart.add_item(@equipment_model)
        @cart.add_item(@equipment_model)
        expect(@cart.items[@equipment_model.id]).to eq(2)
      end
    end

    describe ".remove_item" do
      before (:each) do
        @cart.purge_all
        @cart.add_item(@equipment_model)
      end

      it "removes an item from cart" do
        @cart.remove_item(@equipment_model)
        expect(@cart.items[@equipment_model.id]).to be_nil
      end

      it "decrements if multiple items are in the cart" do
        @cart.add_item(@equipment_model)
        @cart.remove_item(@equipment_model)
        expect(@cart.items[@equipment_model.id]).to eq(1)
      end

    end
  end

  describe "Cart actions" do
    describe ".purge_all" do
      it "should empty the items hash" do
        @cart.purge_all
        expect(@cart.items).to be_empty
      end
    end

    describe ".prepare_all" do
      before(:each) do
        @equipment_model = FactoryGirl.create(:equipment_model)
        @cart.add_item(@equipment_model)
        @cart.add_item(@equipment_model)
        @equipment_model2 = FactoryGirl.create(:equipment_model)
        @cart.add_item(@equipment_model2)
        @cart.start_date = Date.current
        @cart.due_date = (Date.current+1.day)
        @cart.reserver_id = FactoryGirl.create(:user).id
      end
      it "should create an array of reservations" do
        expect(@cart.prepare_all.class).to eq(Array)
        expect(@cart.prepare_all.first.class).to eq(Reservation)
      end
      describe "the reservations" do
        it "should have the correct dates" do
          array = @cart.prepare_all
          array.each do |r|
            expect(r.start_date).to eq(Time.current.midnight)
            expect(r.due_date).to eq(Time.current.midnight + 24.hours)
          end
        end
        it "should have the correct equipment models" do
          array = @cart.prepare_all
          expect(@cart.items).to include(array[1].equipment_model.id)
          expect(@cart.items).to include(array[0].equipment_model.id)
          expect(@cart.items).to include(array[2].equipment_model.id)
        end
        it 'should have the correct reserver ids' do
          array = @cart.prepare_all
          array.each do |r|
            expect(r.reserver_id).to eq @cart.reserver_id
          end
        end
      end
    end
  end

  describe "Aliases" do

    describe ".duration" do
      it "should calculate the sum correctly" do
        @cart.duration.should == @cart.due_date - @cart.start_date + 1
      end
    end

    describe ".reserver" do
      it "should return a correct user instance" do
        @cart.reserver.should == User.find(@cart.reserver_id)
      end
    end
  end

  describe ".empty?" do
    it "is true when there are no items in cart" do
      @cart.items = []
      @cart.empty?.should be_truthy
    end
    it "is false when there are some items in cart" do
      @cart.add_item(FactoryGirl.create(:equipment_model))
      @cart.empty?.should be_falsey
    end
  end

end
