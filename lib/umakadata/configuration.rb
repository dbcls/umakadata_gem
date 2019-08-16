module Umakadata
  class Configuration
    class << self
      def configure(&block)
        new(&block)
      end
    end

    DEFAULT_LOV_URL = 'https://lov.linkeddata.es/dataset/lov/api/v2/vocabulary/list'.freeze

    def initialize
      yield self if block_given?
    end

    attr_writer :lov

    def app_home
      @app_home ||= begin
        File.join(Dir.home, '.umakadata').tap do |home|
          Dir.mkdir(home) unless Dir.exist?(home)
        end
      end
    end

    def lov
      @lov || ENV['UMAKADATA_LOV_URL'] || DEFAULT_LOV_URL
    end
  end
end
