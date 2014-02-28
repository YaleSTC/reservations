require 'spec_helper'

describe Announcement do
  #pending "add some examples to (or delete) #{__FILE__}"
  it "has current scope" do
  	passed = Announcement.create! starts_at: 1.day.ago, ends_at: 1.hour.ago
  	current = Announcement.create! starts_at: 1.hour.ago, ends_at: 1.day.from_now
  	upcoming = Announcement.create! starts_at: 1.hour.from_now, ends_at: 1.from_now
  end

  it "does not include ids passed in to current" do
  	current1 = Announcement.create! starts_at: 1.hour.ago, ends_at: 1.day.from_now
  	current2 = Announcement.create! starts_at: 1.hour.ago, ends_at: 1.day.from_now
  	Announcement.current([current2.id]).should eq([current1])
  end

  it "includes current when nil is passed in" do
  	current = Announcement.create! starts_at: 1.hour.ago, ends_at: 1.day.from_now
  	Announcement.current(nil).should eq([current])
  end
end
