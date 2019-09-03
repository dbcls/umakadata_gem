module Umakadata
  # A class for crawling and evaluating SPARQL endpoint
  class Crawler
    class << self
      def config
        @config ||= Configuration.new
      end
    end

    # @param [String] url an URL of the SPARQL endpoint
    # @param [Hash{Symbol => Object}] options
    def initialize(url, **options)
      @url = url
      @options = options
    end

    # Execute crawling and evaluating
    #
    # @since 1.0.0
    def run
      criteria.each do |method|
        yield method.call
      end
    end

    private

    def ep
      @ep ||= Endpoint.new(@url, **@options)
    end

    def criteria
      @criteria ||= begin
        array = []
        array << ep.availability.method(:alive)
        array << ep.freshness.method(:last_updated)
        array << ep.operation.method(:service_description)
        array << ep.operation.method(:void)
        array << ep.usefulness.method(:metadata)
        array << ep.usefulness.method(:ontology)
        array << ep.usefulness.method(:links_to_other_datasets)
        array << ep.usefulness.method(:data_entry)
        array << ep.usefulness.method(:support_html_format)
        array << ep.usefulness.method(:support_rdfxml_format)
        array << ep.usefulness.method(:support_turtle_format)
        array << ep.validity.method(:cool_uri)
        array << ep.validity.method(:http_uri)
        array << ep.validity.method(:provide_useful_information)
        array << ep.validity.method(:link_to_other_uri)
        array << ep.performance.method(:execution_time)
      end
    end
  end
end
