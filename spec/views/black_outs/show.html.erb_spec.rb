require 'spec_helper'

describe "black_outs/show" do
  before(:each) do
    @black_out = assign(:black_out, stub_model(BlackOut,
      :equipment_model => 1,
      :notice => "MyText",
      :created_by => 2,
      :type => 3
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    rendered.should match(/MyText/)
    rendered.should match(/2/)
    rendered.should match(/3/)
  end
end
