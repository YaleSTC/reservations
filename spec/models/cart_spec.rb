require 'spec_helper'

describe Cart do
  before (:each) do
    @cart = FactoryGirl.build(:cart)
    @cart.items = [] # Needed to avoid db flushing problems
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
      @cart.start_date == Date.today
    end
    it "is due tomorrow" do
      @cart.due_date == Date.tomorrow
    end
    it "has no reserver" do
      @cart.reserver_id.nil?
    end
    it "has errors" do
      @cart.errors.count > 0
    end
  end

  describe ".persisted?" do
    it { @cart.persisted?.should be_false }
  end

  describe "Item handling" do
    before (:each) do
      @equipment_model = FactoryGirl.build(:equipment_model)
    end
    
    describe ".add_item" do
      it "adds an item" do
        expect { @cart.add_item(@equipment_model) }.to change {@cart.items.count}.by(1)
      end
    end

    describe ".remove_item" do
      before (:each) do
        @equipment_model_2 = FactoryGirl.build(:equipment_model)
        @cart.add_item(@equipment_model)
        @cart.add_item(@equipment_model_2)
      end
      
      it "removes an item from cart" do
        lambda {
          @cart.remove_item(@equipment_model)
        }.should change(@cart.items, :count).by(-1)
      end
      
      it "removes a CartReservation from database" do
        expect { @cart.remove_item(@equipment_model) }.to change{CartReservation.all.count}.by(-1)
      end

      it "removes the right model from cart" do
        expect { @cart.remove_item(@equipment_model_2) }.to change { @cart.items.select { |id|
                  CartReservation.where(equipment_model_id: @equipment_model_2).map(&:id).member? id}.count}.by(-1)
      end
    end
  end
  describe "Aliases" do
    describe ".cart_reservations" do
      it "finds items" do
        @cart.cart_reservations.should == CartReservation.find(@cart.items)
      end
    end

    describe ".models_with_quantities" do
      it "gets the correct count of models" do
        # n different models
        n = rand(3..10)
        models = Array.new(n) {FactoryGirl.build(:equipment_model)}

        # add each model to cart arbitrary number of times 
        amounts = Array.new(n) {rand(0..3)} 
        models.each_with_index do |mod, index|
          amounts[index].times {@cart.add_item(mod)} 
        end

        # combine models and amounts into one Hash, omit zero amounts
        result = Hash[models.map(&:id).zip(amounts).select {|mod, amt| amt > 0}]

        @cart.models_with_quantities.should == result
      end
    end

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
      @cart.empty?.should be_true
    end
    it "is false when there are some items in cart" do
      @cart.add_item(FactoryGirl.create(:equipment_model))
      @cart.empty?.should be_false
    end
  end
  
  describe "Reservation date changes" do
    before (:each) do
      n = 5
      n.times {@cart.add_item(FactoryGirl.build(:equipment_model))}
    end

    describe ".set_due_date" do
      it "sets new due dates for all items in cart" do
        date = DateTime.new(Time.now.year + 1, 1, 1) # Prevents the "comparison of Date with ActiveSupport::TimeWithZone failed"
        @cart.set_due_date(date)
        @cart.items.each do |item|
          CartReservation.find(item).due_date.should == date
        end
      end
    end

    describe ".set_start_date" do
      it "does not set a past date as start date" do
        date = DateTime.new(Time.now.year - 1, 1, 1)
        @cart.set_start_date(date)
        @cart.items.each do |item|
          CartReservation.find(item).start_date.should >= Date.today
        end
      end
      it "sets new start and due dates for all items in cart" do
        date = DateTime.new(Time.now.year + 1, 1, 1)
        @cart.set_start_date(date)
        @cart.items.each do |item|
          CartReservation.find(item).start_date.should == date
        end
      end
    end

    # If broken, then .set_due_date and .set_start_date are broken
    describe ".fix_due_date" do
      it "sets due date as start_date + 1 if due date precedes start date" do
        @cart.start_date = 1.week.from_now
        @cart.due_date = 1.year.ago
        expect { @cart.fix_due_date }.to change{@cart.due_date}.to(@cart.start_date + 1.day)
      end
      it "does not affect due date when due date does not precede start date" do
        dates = [[1.week.ago, 2.days.ago],
                 [1.day.ago, DateTime.now],
                 [DateTime.now, DateTime.tomorrow],
                 [1.week.from_now, 1.month.from_now]] # past, current, future dates
        dates.each do |start, due|
          @cart.start_date = start
          @cart.due_date = due
          expect { @cart.fix_due_date }.to_not change{@cart.due_date}
        end
      end
    end
  end
  
  describe ".set_reserver_id" do
    it "should flag every CartReservation with passed user_id" do
      user_id = FactoryGirl.create(:user).id
      @cart.add_item(FactoryGirl.build(:equipment_model))
      @cart.set_reserver_id(user_id)
      
      @cart.items.each do |item|
        CartReservation.find(item).reserver_id.should == user_id
      end
    end
  end
  
  ### TODO: Error-handling functions
  ### TODO: .renewable_reservations (not called from anywhere)
end