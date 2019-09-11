require 'umakadata/logger'

module Umakadata
  class Configuration
    class << self
      def configure(&block)
        new(&block)
      end
    end

    DEFAULT_LOV_URL = 'https://lov.linkeddata.es/dataset/lov/api/v2/vocabulary/list'.freeze

    LoggerConfig = Struct.new(:level) do
      def options
        {
          logdev: STDERR,
          level: level,
          formatter: Umakadata::Logger::Formatter.new
        }
      end
    end

    def initialize
      set_default
      yield self if block_given?
    end

    attr_accessor :logger
    attr_accessor :backtrace
    attr_accessor :lov

    def app_home
      @app_home ||= begin
        File.join(Dir.home, '.umakadata').tap do |home|
          Dir.mkdir(home) unless Dir.exist?(home)
        end
      end
    end

    private

    def set_default
      @logger = LoggerConfig.new(::Logger::INFO)
      @backtrace = false
      @lov = ENV['UMAKADATA_LOV_URL'] || DEFAULT_LOV_URL
    end
  end
end
