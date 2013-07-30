require 'spec_helper'

describe "Announcements" do 
	it "displays active announcements" do 
  	Announcement.create! message: "Hello World", starts_at: 1.hour.ago, ends_at: 1.hour.from_now
  	Announcement.create! message: "Upcoming", starts_at: 10.minutes.from_now, ends_at: 1.hour.from_now
  	visit root_path
  	page.should have_content("Hello World")
  	page.should_not have_content("Upcoming")
  	click_on "hide announcement"
  	page.should_not have_content("Hello World")
  end
end
