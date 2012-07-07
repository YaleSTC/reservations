require 'spec_helper'

describe "black_outs/index" do
  before(:each) do
    assign(:black_outs, [
      stub_model(BlackOut,
        :equipment_model => 1,
        :notice => "MyText",
        :created_by => 2,
        :type => 3
      ),
      stub_model(BlackOut,
        :equipment_model => 1,
        :notice => "MyText",
        :created_by => 2,
        :type => 3
      )
    ])
  end

  it "renders a list of black_outs" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => 3.to_s, :count => 2
  end
end
