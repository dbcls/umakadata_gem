module Umakadata

  module Util
    def force_encode(s)
      return nil if s.nil?
      s.force_encoding('UTF-8') unless s.encoding == Encoding::UTF_8
      s = s.encode('UTF-16BE', :invalid => :replace, :undef => :replace, :replace => '?').encode("UTF-8") unless s.valid_encoding?
      return s
    end
  end

end
