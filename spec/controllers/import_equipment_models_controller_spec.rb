require 'spec_helper'

describe ImportEquipmentModelsController do

  describe "GET 'import'" do
    it "returns http success" do
      get 'import'
      response.should be_success
    end
  end

  describe "GET 'import_page'" do
    it "returns http success" do
      get 'import_page'
      response.should be_success
    end
  end

end
