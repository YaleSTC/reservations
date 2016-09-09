# frozen_string_literal: true
require 'spec_helper'

describe Announcement, type: :model do
  # pending "add some examples to (or delete) #{__FILE__}"
  it 'has current scope' do
    _passed = Announcement.create! starts_at: Time.zone.today - 2.days,
                                   ends_at: Time.zone.today - 1.day,
                                   message: 'MyText'
    _current = Announcement.create! starts_at: Time.zone.today - 1.day,
                                    ends_at: Time.zone.today + 1.day,
                                    message: 'MyText'
    _upcoming = Announcement.create! starts_at: Time.zone.today + 1.day,
                                     ends_at: Time.zone.today + 2.days,
                                     message: 'MyText'
  end

  it 'does not include ids passed in to current' do
    current1 = Announcement.create! starts_at: Time.zone.today - 1.day,
                                    ends_at: Time.zone.today + 1.day,
                                    message: 'MyText'

    current2 = Announcement.create! starts_at: Time.zone.today - 1.day,
                                    ends_at: Time.zone.today + 1.day,
                                    message: 'MyText'

    expect(Announcement.current([current2.id])).to eq([current1])
  end

  it 'includes current when nil is passed in' do
    current = Announcement.create! starts_at: Time.zone.today - 1.day,
                                   ends_at: Time.zone.today + 1.day,
                                   message: 'MyText'

    expect(Announcement.current(nil)).to eq([current])
  end
end
