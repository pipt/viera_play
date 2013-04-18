class TimeStamp
  def self.parse(string)
    if /\A(-?)([0-9]{1,2}):([0-9]{2}):([0-9]{2})\Z/.match(string)
      negative, parts = $1, [$2, $3, $4]
      parts = parts.map(&:to_i)
      val = parts[0] * 60**2 + parts[1] * 60 + parts[2]
      val = -val if negative == '-'
      new(val)
    else
      raise ArgumentError, "Bad timestamp" unless match
    end
  end

  def to_s
    mins, seconds = @val.to_i.abs.divmod(60)
    hours, mins = mins.divmod(60)

    neg = '-' if @val < 0
    "%s%02i:%02i:%02i" % [neg, hours, mins, seconds]
  end

  def initialize(val)
    @val = val
  end

  def to_i
    @val
  end

  def + other
    to_i + other.to_i
  end
end
