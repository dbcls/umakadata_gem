require 'rdf/turtle'
require 'umakadata/linkset'
require 'umakadata/data_format'
require 'umakadata/logging/log'

module Umakadata

  class VoID

    include Umakadata::DataFormat
    include Umakadata::Linkset
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

    ##
    # return the linksets of VoID
    #
    # @return [Array]
    attr_reader :linkset

    def initialize(http_response, logger: nil)
      body = http_response.body
      data = triples(body, TURTLE)
      logger.result = 'VoID is in Turtle format' unless logger.nil? || data.nil?
      if data.nil?
        data = triples(body, RDFXML)
        logger.result = 'VoID is in RDF/XML format' unless logger.nil?
      end
      if data.nil?
        logger.result = 'VoID is invalid (valid formats: Turtle or RDF/XML)' unless logger.nil?
        return
      end

      @text = body
      @license = []
      @publisher = []
      data.each do |subject, predicate, object|
        @license.push object.to_s if predicate == RDF::URI('http://purl.org/dc/terms/license')
        @publisher.push object.to_s if predicate == RDF::URI('http://purl.org/dc/terms/publisher')
      end

      @linkset = self.linksets(data)
    end
  end
end
