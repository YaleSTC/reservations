require 'spec_helper'

describe "making a reservation", type: feature do
  before(:all) {
    @app_config = FactoryGirl.create(:app_config)
  }
  before {
    @controller.stub(:first_time_user).and_return(:nil)
  }

  context 'as a patron' do
    before do
      @user = FactoryGirl.create(:user)
      @controller.stub(:current_user).and_return(@user)
    end

    it "adds an item to the cart from catalog" do
      visit "/"
      click_link 'Add To Cart'
      expect(session[:cart].equipment_models.size).to eq(1)
    end

    it "changes the start date" do
      within("#cart_dates") do
        fill_in 'start_date', with: Date.tomorrow
      end
      expect(session[:cart].start_date).to eq(Date.tomorrow)
    end

    it "changes the due date" do
      within("#cart_dates") do
        fill_in 'due_date', with: Date.tomorrow + 2.day
      end
      expect(session[:cart].due_date).to eq(Date.tomorrow + 2.day)
    end

    it "clicks the Make Reservation button" do
      click_link "Make Reservation"
      expect(page).to have_content "Confirm Reservation"
      expect(page).to have_content "Cart start date"
      expect(page).to have_content "Cart due date"
    end

    it "clicks the Finalize Reservation button" do
      click_link "Finalize Reservation"
    end

  end
end
