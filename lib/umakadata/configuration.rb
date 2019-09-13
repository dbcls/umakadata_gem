require 'umakadata/logger'

module Umakadata
  class Configuration
    class << self
      def configure(&block)
        new(&block)
      end
    end

    DEFAULT_LOV_URL = 'https://lov.linkeddata.es/dataset/lov/api/v2/vocabulary/list'.freeze

    def initialize
      set_default
      yield self if block_given?
    end

    attr_writer :logger
    attr_accessor :logger_config
    attr_accessor :backtrace
    attr_accessor :lov

    def app_home
      @app_home ||= begin
        File.join(Dir.home, '.umakadata').tap do |home|
          Dir.mkdir(home) unless Dir.exist?(home)
        end
      end
    end

    def logger
      @logger ||= ::Logger.new((options = @logger_config.dup).delete(:logdev), options)
    end

    private

    def set_default
      @logger_config = {
        logdev: STDERR,
        level: ::Logger::INFO,
        formatter: Umakadata::Logger::Formatter.new
      }
      @backtrace = false
      @lov = ENV['UMAKADATA_LOV_URL'] || DEFAULT_LOV_URL
    end
  end
end
