require 'spec_helper'

describe "black_outs/edit" do
  before(:each) do
    @black_out = assign(:black_out, stub_model(BlackOut,
      :equipment_model => 1,
      :notice => "MyText",
      :created_by => 1,
      :type => 1
    ))
  end

  it "renders the edit black_out form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => black_outs_path(@black_out), :method => "post" do
      assert_select "input#black_out_equipment_model", :name => "black_out[equipment_model]"
      assert_select "textarea#black_out_notice", :name => "black_out[notice]"
      assert_select "input#black_out_created_by", :name => "black_out[created_by]"
      assert_select "input#black_out_type", :name => "black_out[type]"
    end
  end
end
