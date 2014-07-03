require 'spec_helper'

describe "go to the catalog", type: feature do

  before(:all) do
    @app_config = FactoryGirl.create(:app_config)
    @user = FactoryGirl.create(:user)
  end

  after(:all) do
    User.delete_all
  end
  it 'goes to the bloody catalog' do

    ActionView::Base.any_instance.stub(:current_user).and_return(@user)
    puts @user.attributes
    visit "/"
    save_and_open_page

    # fill_in 'user_login', with: 'csw3'
    #fill_in 'user_first_name', with: 'casey'
    #fill_in 'user_last_name', with: 'watts'
    #fill_in 'user_email', with: 'email@email.com'
    #fill_in 'user_affiliation', with: 'your mom'

    #click_button 'Create User'

    #expect(page).to have_content('Catalog')

  end
end
