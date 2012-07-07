require 'spec_helper'

describe "BlackOuts" do
  describe "GET /black_outs" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get black_outs_path
      response.status.should be(200)
    end
  end
end
