require 'spec_helper'
require 'capybara/rails'

# Warden test mode for authentication
Warden.test_mode!

describe "login process", :type => :feature do
  before :each do
    app_setup
    @user = FactoryGirl.create(:admin)
    login_as(@user, scope: :user)
  end

  it "can allow a user to see the main catalog page" do
    visit "/"
    # save_and_open_page
    expect(page).to have_content 'Catalog'
  end
end

def app_setup
  @app_config = FactoryGirl.create(:app_config)
  @equipment_model_with_object = FactoryGirl.create(:equipment_model_with_object)
end