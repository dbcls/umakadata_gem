require 'forwardable'

module Umakadata
  # A class for crawling and evaluating SPARQL endpoint
  class Crawler
    extend Forwardable

    class << self
      def config
        @config ||= Configuration.new
      end
    end

    # @param [String] url an URL of the SPARQL endpoint
    # @param [Hash{Symbol => Object}] options
    def initialize(url, **options)
      @url = url
      @logger = Umakadata::Crawler.config.logger
      @options = options
    end

    def_delegators :@logger, :debug, :info, :warn, :error, :fatal

    # Execute crawling and evaluating
    #
    # @since 1.0.0
    def run
      criteria.each do |criterion|
        criterion.measurements.each do |measurement|
          debug('Crawler') { "call #{criterion.class.name.demodulize}.#{measurement.name}" }
          yield measurement.call
        end
      end
    end

    def_delegator :ep, :basic_information

    private

    def ep
      @ep ||= Endpoint.new(@url, **@options)
    end

    def criteria
      @criteria ||= [
        ep.availability,
        ep.freshness,
        ep.operation,
        ep.usefulness,
        ep.validity,
        ep.performance
      ]
    end
  end
end
