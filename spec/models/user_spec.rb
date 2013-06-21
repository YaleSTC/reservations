require 'spec_helper'

describe User do
  before(:each) do
    @beyonce = FactoryGirl.build(:user)
  end
  it "has a working factory" do\
    @beyonce.save.should be_true
  end

  it "requires a login (netid)" do
    @beyonce.login = ""
    @beyonce.save.should be_false
    @beyonce.login = "bgk1"
    @beyonce.save.should be_true
  end

  it "must have a unique login" do
    @beyonce.save
    @beyonce_doppleganger = FactoryGirl.build(:user)
    @beyonce_doppleganger.save.should be_false
  end

  it "must have a first name" do
    @beyonce.first_name = ""
    @beyonce.save.should be_false
    @beyonce.first_name = "Beyonce"
    @beyonce.save.should be_true
  end

  it "must have a last name" do
    @beyonce.last_name = ""
    @beyonce.save.should be_false
    @beyonce.last_name = "Knowles"
    @beyonce.save.should be_true
  end

  it "must have an affiliation" do
    @beyonce.affiliation = ""
    @beyonce.save.should be_false
    @beyonce.affiliation = "Destiny's Child"
    @beyonce.save.should be_true
  end

  it "must have a phone number" do
    @beyonce.phone = ""
    @beyonce.save.should be_false
    @beyonce.phone = "555-555-5555"
    @beyonce.save.should be_true
  end

  # figure out what the regex is that's actually used in this validation
  it "phone number must be ??" do
    @beyonce.phone = "555-555-5#55"
    @beyonce.save.should be_false
    @beyonce.phone = "55555555"
    @beyonce.save.should be_true
  end

  it "must have an email" do
    @beyonce.email = ""
    @beyonce.save.should be_false
    @beyonce.email = "beyonce.knowles@yale.edu"
    @beyonce.save.should be_true
  end

  # figure out this regex as well in order to ensure that there is good test coverage
  it "email must take the standard email format (sometext@something.something)"
  it "nickname must not have any non-standard characters (see validation)"

  it "nickname may be blank or nil" do
    @beyonce.nickname = nil
    @beyonce.save.should be_true
    @beyonce.nickname = ""
    @beyonce.save.should be_true
  end

  #TODO: figure out why it's allowing me to save with a false param
  it "must accept ToS" do
    @beyonce.terms_of_service_accepted = false
    @beyonce.save.should be_false
    @beyonce.terms_of_service_accepted = true
    @beyonce.save.should be_true
  end

  # this test means nothing if the previous one fails
  it "doesn't have to accept ToS if created by an admin" do
    @user_made_by_admin = FactoryGirl.build(:user, created_by_admin: true, terms_of_service_accepted: false)
    @user_made_by_admin.save.should be_true
  end

end
