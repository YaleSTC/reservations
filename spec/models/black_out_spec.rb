require 'spec_helper'

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

end
