require 'spec_helper'

describe AppConfig do
  before(:each) do
    @ac = FactoryGirl.build(:app_config)
  end
  it "has a working factory"
  it "has a site title"
  it "has a short enough site title"
  it "shouldn't have an invalid e-mail" do
    emails = ["ana@com", "anda@pres,com", nil, " "]
    emails.each do |invalid|
      @ac.admin_email = invalid
      @ac.should_not be_valid
    end
  end
  it "should have a valid and present e-mail" do
    @ac.admin_email = "ana@yale.edu"
    @ac.should be_valid
  end
  it "has an attachment that could serve as favicon"
  it "has an attachment that is of the favicon format"
end
