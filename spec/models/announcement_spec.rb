require 'spec_helper'

describe Announcement, type: :model do
  # pending "add some examples to (or delete) #{__FILE__}"
  # rubocop:disable UnusedLocalVariable, UselessAssignment
  it 'has current scope' do
    passed = Announcement.create! starts_at: 1.day.ago,
                                  ends_at: 1.hour.ago,
                                  message: 'MyText'
    current = Announcement.create! starts_at: 1.hour.ago,
                                   ends_at: 1.day.from_now,
                                   message: 'MyText'
    upcoming = Announcement.create! starts_at: 1.hour.from_now,
                                    ends_at: 1.day.from_now,
                                    message: 'MyText'
  end
  # rubocop:enable UnusedLocalVariable, UselessAssignment

  it 'does not include ids passed in to current' do
    current1 = Announcement.create! starts_at: 1.hour.ago,
                                    ends_at: 1.day.from_now,
                                    message: 'MyText'

    current2 = Announcement.create! starts_at: 1.hour.ago,
                                    ends_at: 1.day.from_now,
                                    message: 'MyText'

    expect(Announcement.current([current2.id])).to eq([current1])
  end

  it 'includes current when nil is passed in' do
    current = Announcement.create! starts_at: 1.hour.ago,
                                   ends_at: 1.day.from_now,
                                   message: 'MyText'

    expect(Announcement.current(nil)).to eq([current])
  end
end
