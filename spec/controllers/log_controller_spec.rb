require 'spec_helper'

describe LogController, type: :controller, versioning: true do
  render_views

  before(:all) do
    @app_config = FactoryGirl.create(:app_config)
  end
  before(:each) do
    PaperTrail.enabled = true
    allow(@controller).to receive(:first_time_user).and_return(FactoryGirl.create(:user))
    allow(@controller).to receive(:current_user).and_return(FactoryGirl.create(:admin))
    PaperTrail.whodunnit = @controller.current_user
      # Necessary because for some reason, user ID that is responsible for
      # changes is deleted between tests
    @reservation = FactoryGirl.create(:valid_reservation)
    PaperTrail.enabled = false
  end

  # Attempting to destroy the @reservation messes up the test database.
  # No idea why.

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      expect(response).to be_success
    end

    it "contains links to all individual-version views, regardless of object type" do
      get :index
      PaperTrail::Version.last(20).each do |v|
        expect(response.body).to include version_view_path(v.id)
      end
    end
  end

  describe "GET 'version/:id'" do

    it "returns http success if :id exists" do
      get 'version', id: @reservation.versions.first.id
      expect(response).to be_success
    end

    it "redirects to index if :id doesn't exist" do
      get 'version', id: 0
      expect(response).to redirect_to('/log/index')
    end
  end

  describe "GET 'history/:object_type/:id'" do
    it "returns http success if Reservation :id exists" do
      get 'history', id: @reservation.id, object_type: :reservation
      expect(response).to be_success
    end

    it "redirects to index if Reservation :id doesn't exist" do
      get 'history', id: 0, object_type: :reservation
      expect(response).to be_redirect
    end
  end
end
