require 'spec_helper'

describe LogController, versioning: true do
  before(:all) do
    @app_config = FactoryGirl.create(:app_config)
  end
  before(:each) do
    PaperTrail.enabled = true
    @controller.stub(:first_time_user).and_return(FactoryGirl.create(:user))
    @controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
    PaperTrail.whodunnit = @controller.current_user
      # Necessary because for some reason, user ID that is responsible for
      # changes is deleted between tests
    @reservation = FactoryGirl.create(:reservation)
    @reservation.update_attributes(start_date: 1.day.ago)
    @reservation.save
    PaperTrail.enabled = false
  end

  # Attempting to destroy the @reservation messes up the test database.
  # No idea why.

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_success
    end

    it "contains all versions, regardless of object type"
    it "contains links to individual-version view"
    it "contains links to individual-item version overview"
  end

  describe "GET 'version/:id'" do

    it "returns http success if :id exists" do
      get 'version', id: @reservation.versions.first.id
      response.should be_success
    end

    it "redirects to index if :id doesn't exist" do
      get 'version', id: 99999
      response.should redirect_to('/log/index')
    end
  end

  describe "GET 'history/:id'" do
    it "returns http success if Reservation :id exists" do
      get 'history', id: @reservation.id, object_type: :reservation
      response.should be_success
    end

    it "redirects to index if Reservation :id doesn't exist" do
      get 'history', id: 99999, object_type: :reservation
      response.should be_redirect
    end
  end
end
