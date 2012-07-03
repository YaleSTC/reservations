require 'spec_helper'

describe 'home' do

  it 'should have the word FHQWHGADS (this shows you what an error looks like lol)' do
    admin = FactoryGirl.create(:admin)
    visit "/"
    page.should have_content('fhqwhgads')
  end
end
