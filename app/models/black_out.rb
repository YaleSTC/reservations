class BlackOut < ActiveRecord::Base

  belongs_to :equipment_model
  attr_accessible :start_date, :end_date, :notice, :equipment_model_id, :black_out_type, :created_by, :set_id

  attr_accessor :days # needed for days of the week checkboxes in new_recurring

  validates :notice,
            :start_date,
            :equipment_model_id,
            :black_out_type,
            :end_date, :presence => true

  def self.black_outs_on_date(date) # Returns the black_out object that blacks out the day if the day is blacked out. Otherwise, returns an empty array.
    black_outs = []
    BlackOut.all.each do |black_out|
      if ((black_out.start_date..black_out.end_date).cover?(date.to_date))
        black_outs << black_out
      end
    end
    black_outs
  end
  #TODO: fix typo here and everywhere that this method is called. While at it, put a space in black_out since that's
  # it is everywhere else.
  def self.hard_backout_exists_on_date(date)
    black_outs = self.black_outs_on_date(date)
    if black_outs && black_outs.map(&:black_out_type).include?('hard')
      return true
    else
      return false
    end
  end

  def self.array_of_black_outs(start_date, end_date, days)
    array = []
    date_range = start_date..end_date
    date_range.each do |date|
      if days.include?(date.wday.to_s) # because it's passed as a string
        array << date
      end
    end
    return array
  end

end

