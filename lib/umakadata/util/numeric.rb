class Integer
  def self.safe_convert(value)
    Integer(value)
  rescue StandardError
    nil
  end
end

class Float
  def self.safe_convert(value)
    Float(value)
  rescue StandardError
    nil
  end
end
