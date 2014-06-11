require 'spec_helper'

describe LogController do

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_success
    end
  end

  describe "GET 'version/:id'" do
    it "returns http success if :id exists" do
      get 'version', id: 1
      response.should be_success
    end

    xit "redirects to index if :id doesn't exist" do
      get 'version', id: 99999
      response.should redirect_to('log/index')
    end
  end

  describe "GET 'history/:id'" do
    it "returns http success if Reservation :id exists" do
      get 'history', id: 1
      response.should be_success
    end

    xit "redirects to index if Reservation :id doesn't exist" do
      get 'history', id: 99999
      response.should be_redirect
    end
  end
end
