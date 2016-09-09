# frozen_string_literal: true
require 'spec_helper'

describe 'Announcements' do
  before :each do
    Announcement.create! message: 'Hello World',
                         starts_at: Time.zone.today - 1.day,
                         ends_at: Time.zone.today + 1.day
    Announcement.create! message: 'Upcoming',
                         starts_at: Time.zone.today + 1.day,
                         ends_at: Time.zone.today + 2.days
  end

  it 'displays active announcements' do
    visit '/'
    expect(page).to have_content('Hello World')
    expect(page).not_to have_content('Upcoming')
  end

  # 2014-10-24
  # Testing the close button is problematic because I think we're using a JS
  # response and for some reason selenium isn't liking it. I also ran into
  # issues with missing routes for 'favicon.ico' unless I make the before
  # block "before :all".

  # context "after pressing the close button", :js => true do
  #   before do
  #     visit '/'
  #     click_button('close_announcement')
  #     visit current_path
  #   end
  #   it { expect(page).not_to have_content("Hello World") }
  # end
end
