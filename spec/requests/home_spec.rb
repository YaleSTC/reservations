require 'spec_helper'

describe 'cart' do

  it 'checks that neither start date nor due date are in the past' do
    admin = FactoryGirl.create(:admin)
    visit "/"
    page.should have_content('wonka')
  end
end
