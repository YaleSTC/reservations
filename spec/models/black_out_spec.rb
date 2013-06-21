require 'spec_helper'

# TODO: write test for   belongs_to :equipment_model

describe BlackOut do
  it "does not allow a blank notice" do
    @vacation = FactoryGirl.build(:black_out, notice: "")
    @vacation.save.should be_false
    @vacation.notice = "It's spring break!"
    @vacation.save.should be_true
  end

  it "validates presence of start date" do
    @spring_break = FactoryGirl.build(:black_out, start_date: "")
    @spring_break.save.should be_false
    @spring_break.start_date = "2013-03-05"
    @spring_break.save.should be_true
  end

  it "validates presence of end date" do
    @spring_break = FactoryGirl.build(:black_out, end_date: "")
    @spring_break.save.should be_false
    @spring_break.end_date = "2013-03-22"
    @spring_break.save.should be_true
  end

  it "validates presence of black out type" do
    @spring_break = FactoryGirl.build(:black_out, black_out_type: "")
    @spring_break.save.should be_false
    @spring_break.black_out_type = "hard"
    @spring_break.save.should be_true
  end

  # what does this even do? I see no evidence of this elsewhere in the application
  it "validates presence of equipment_model_id" do
  end

  it "validates a set_id if it is a recurring black out" do
    # new feature
  end

  describe ".black_outs_on_date" do
    before(:each) do
      @black_out = FactoryGirl.create(:black_out)
      @another_black_out = FactoryGirl.create(:black_out, end_date: "2013-03-18")
    end

    it "Should return the black_out blocking a passed date if exists" do
      BlackOut.black_outs_on_date("2013-03-20").should == [@black_out]
    end
    it "Should return nil if the date is not blacked out" do
      BlackOut.black_outs_on_date("2013-03-30").should == []
    end
    it "Should return an array if multiple blackouts cover date" do
      BlackOut.black_outs_on_date("2013-03-15").should == [@black_out, @another_black_out]
    end
  end

  describe ".hard_backout_exists_on_date" do
    before(:each) do
      @spring_break = FactoryGirl.create(:black_out)
      @summer_break = FactoryGirl.create(:black_out, black_out_type: 'soft', start_date: "2013-06-01", end_date: "2013-09-01")
    end
    it "Should return true if there is a hard blackout on the given date" do
      BlackOut.hard_backout_exists_on_date("2013-03-17").should == true
    end
    it "Should return false if there is a soft blackout or no blackout on the given date" do
      BlackOut.hard_backout_exists_on_date("2013-07-01").should == false
      BlackOut.hard_backout_exists_on_date("2013-05-01").should == false
    end
  end

end
