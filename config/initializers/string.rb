class String
  def to_date
    begin
      Date.strptime(self, '%m/%d/%Y')
    rescue ArgumentError
      Date.parse(self, false) unless blank?
    end
  end

  def to_datetime
    begin
      DateTime.strptime(self,'%m/%d/%Y')
    rescue ArgumentError
      DateTime.parse(self, false) unless blank?
    end
  end

  def to_time(form = :local)
    begin
      Time.strptime(self,'%m/%d/%Y')
    rescue ArgumentError
      parts = Date._parse(self, false)
      return if parts.empty?

      now = Time.now
      time = Time.new(
        parts.fetch(:year, now.year),
        parts.fetch(:mon, now.month),
        parts.fetch(:mday, now.day),
        parts.fetch(:hour, 0),
        parts.fetch(:min, 0),
        parts.fetch(:sec, 0) + parts.fetch(:sec_fraction, 0),
        parts.fetch(:offset, form == :utc ? 0 : nil)
      )

      form == :utc ? time.utc : time.getlocal
    end
  end

end
