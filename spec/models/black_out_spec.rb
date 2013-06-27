require 'spec_helper'

describe BlackOut do
  context "validations and associations" do
    it { should validate_presence_of(:notice) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }
    it { should validate_presence_of(:black_out_type) }
    it { should validate_presence_of(:equipment_model_id) } # I don't think that this is used anywhere else in the application

    it { should belong_to(:equipment_model) }

    it "validates a set_id if it is a recurring blackout"
      # new feature that should exist already
  end

  describe ".blackouts_on_date" do
    before(:each) do
      @blackout = FactoryGirl.create(:black_out, start_date: "2013-03-05", end_date: "2013-03-22")
      @another_blackout = FactoryGirl.create(:black_out, start_date: "2013-03-05", end_date: "2013-03-18")
    end

    it "Should return the black_out blocking a passed date if exists" do
      BlackOut.blackouts_on_date("2013-03-20").should == [@blackout]
    end
    it "Should return nil if the date is not blacked out" do
      BlackOut.blackouts_on_date("2013-03-30").should == []
    end
    it "Should return an array if multiple blackouts cover date" do
      BlackOut.blackouts_on_date("2013-03-15").should == [@blackout, @another_blackout]
    end
  end

  describe ".hard_blackout_exists_on_date" do
    before(:each) do
      @spring_break = FactoryGirl.create(:black_out, black_out_type: 'hard', start_date: "2013-03-05", end_date: "2013-03-22")
      @summer_break = FactoryGirl.create(:black_out, black_out_type: 'soft', start_date: "2013-06-01", end_date: "2013-09-01")
    end
    it "Should return true if there is a hard blackout on the given date" do
      BlackOut.hard_blackout_exists_on_date("2013-03-17").should == true
    end
    it "Should return false if there is a soft blackout or no blackout on the given date" do
      BlackOut.hard_blackout_exists_on_date("2013-07-01").should == false
      BlackOut.hard_blackout_exists_on_date("2013-05-01").should == false
    end
  end

end
