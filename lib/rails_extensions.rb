require 'date'

class Range
  def intersection(other)
    return nil if (self.max < other.begin or other.max < self.begin)
    [self.begin, other.begin].max..[self.max, other.max].min
  end
  alias_method :&, :intersection
end

class Date
  def self.today
    Date.current
  end
  def self.tomorrow
    Date.current + 1.day
  end
  def self.yesterday
    Date.current - 1.day
  end
end
