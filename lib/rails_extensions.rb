require 'date'

class Range
  def intersection(other)
    return nil if max < other.begin || other.max < self.begin
    [self.begin, other.begin].max..[max, other.max].min
  end
  alias_method :&, :intersection
end