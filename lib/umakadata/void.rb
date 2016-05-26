require 'rdf/turtle'
require 'umakadata/data_format'
require 'umakadata/logging/criteria_log'

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

    ##
    # return the last_modified of some VoID data
    #
    # @return [String]
    attr_reader :modified

    def initialize(http_response, logger: nil)
      body = http_response.body
      data = triples(body, TURTLE)
      logger.result = 'VoID can be retrieved Turtle format' unless data.nil?
      if data.nil?
        data = triples(body, RDFXML)
        logger.result = 'VoID can be retrieved RDF/XML format' unless data.nil?
      end
      if data.nil?
        logger.result = 'VoID can not be retrieved Turtle and RDF/XML format'
        return
      end

      @text = body
      @license = []
      @publisher = []
      time = []
      data.each do |subject, predicate, object|
        @license.push object.to_s if predicate == RDF::URI('http://purl.org/dc/terms/license')
        @publisher.push object.to_s if predicate == RDF::URI('http://purl.org/dc/terms/publisher')
        if predicate == RDF::URI('http://purl.org/dc/terms/modified')
          time.push Time.parse(object.to_s) rescue time.push nil
        end
      end

      @modified = time.compact.max
    end
  end
end
