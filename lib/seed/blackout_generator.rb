# frozen_string_literal: true
module BlackoutGenerator
  def self.generate
    Blackout.create! do |blk|
      blk.start_date = rand(Time.zone.now..Time.zone.now + 1.year)
      blk.end_date = rand(blk.start_date..blk.start_date.next_week)
      blk.notice = FFaker::HipsterIpsum.paragraph(2)
      blk.created_by = User.first.id
      blk.blackout_type = %w(soft hard).sample
    end
  end
end
