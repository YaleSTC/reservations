require 'spec_helper'

describe "Announcements" do
	it "displays active announcements" do
  	Announcement.create! message: "Hello World", starts_at: 1.hour.ago, ends_at: 1.hour.from_now
  	Announcement.create! message: "Upcoming", starts_at: 10.minutes.from_now, ends_at: 1.hour.from_now
  	visit '/catalog'
  	page.should have_content("Hello World")
  	page.should_not have_content("Upcoming")
    # check also that pressing the close button successfully closes the flash announcement.
    # for some reason capybara is not finding the button correctly -- someone with frontend
    # experience look at this?
    # click_on('.close')
  	# page.should_not have_content("Hello World")
  end
end
