require 'date'

class Range
  def intersection(other)
    return nil if (self.max < other.begin or other.max < self.begin) 
    [self.begin, other.begin].max..[self.max, other.max].min
  end
  alias_method :&, :intersection
end
