require 'spec_helper'

describe 'login process' do
  before :each do
    app_setup
    @user = FactoryGirl.create(:admin)
    login_as(@user, scope: :user)
  end

  it 'can allow a user to see the main catalog page' do
    visit '/'
    # save_and_open_page
    expect(page).to have_content 'Catalog'
  end

  it 'allows admins to see the users index' do
    visit '/users'
    expect(page).to have_content 'Users'
  end
end

def app_setup
  @app_config = FactoryGirl.create(:app_config)
  @equipment_model_with_object = FactoryGirl.create(:equipment_model_with_object)
end
