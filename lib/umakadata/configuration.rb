require 'umakadata/logger'

module Umakadata

  # A class that represents Umakadata crawler configuration
  #
  # @!attribute backtrace
  #   @return [True, False] whther if store backtraces for exceptions
  # @!attribute logger
  #   @return [Logger] a logger instance
  # @!attribute lov
  #   @return [String] an URL
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

    attr_accessor :backtrace
    attr_accessor :logger
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
      @backtrace = false
      @lov = ENV['UMAKADATA_LOV_URL'] || DEFAULT_LOV_URL
      options = Umakadata::Logger::DEFAULT_CONFIG.dup
      @logger = ::Logger.new(options.delete(:logdev), options)
    end
  end
end
