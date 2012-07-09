require "spec_helper"

describe BlackOutsController do
  describe "routing" do

    it "routes to #index" do
      get("/black_outs").should route_to("black_outs#index")
    end

    it "routes to #new" do
      get("/black_outs/new").should route_to("black_outs#new")
    end

    it "routes to #show" do
      get("/black_outs/1").should route_to("black_outs#show", :id => "1")
    end

    it "routes to #edit" do
      get("/black_outs/1/edit").should route_to("black_outs#edit", :id => "1")
    end

    it "routes to #create" do
      post("/black_outs").should route_to("black_outs#create")
    end

    it "routes to #update" do
      put("/black_outs/1").should route_to("black_outs#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/black_outs/1").should route_to("black_outs#destroy", :id => "1")
    end

  end
end
