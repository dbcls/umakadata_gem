require 'rdf/turtle'
require 'umakadata/data_format'
require 'umakadata/logging/log'

module Umakadata

  class VoID

    include Umakadata::DataFormat
    ##
    # return the VoID as string
    #
    # @return [String]
    attr_reader :text

    ##
    # return the license of VoID
    #
    # @return [Array]
    attr_reader :license

    ##
    # return the publisher of VoID
    #
    # @return [Array]
    attr_reader :publisher

    FORMATS = { "N-Triples" => NTRIPLES, "Turtle" => TURTLE, "RDF/XML" => RDFXML, "N3" => N3, "RDFa" => RDFA }

    def initialize(http_response, logger: nil)
      body = http_response.body
      data = nil
      FORMATS.each do |key, value|
        break unless data.nil?
        data = triples(body, value)
        logger.result = "VoID is in #{key} format" unless logger.nil?
      end
      if data.nil?
        logger.result = "VoID is invalid (valid formats: #{FORMATS.keys.join(',')})" unless logger.nil?
        return
      end

      @text = body
      @license = []
      @publisher = []
      data.each do |subject, predicate, object|
        @license.push object.to_s if predicate == RDF::URI('http://purl.org/dc/terms/license')
        @publisher.push object.to_s if predicate == RDF::URI('http://purl.org/dc/terms/publisher')
      end
    end
  end
end
