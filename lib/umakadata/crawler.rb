module Umakadata
  class Crawler
    class << self
      def config
        @config ||= Configuration.new
      end
    end
  end
end
