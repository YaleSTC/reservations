class String
  def to_date
    begin
      Date.strptime(self, '%m/%d/%Y')
    rescue ArgumentError
      Date.strptime(self, '%Y-%m-%d')
    end
  end
end
