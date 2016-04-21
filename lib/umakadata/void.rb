require 'rdf/turtle'
require 'umakadata/data_format'
require 'umakadata/error_helper'

module Umakadata

  class VoID

    include Umakadata::DataFormat
    include Umakadata::ErrorHelper

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

    def initialize(http_response)
      body = http_response.body
      data = triples(body, TURTLE)
      data = triples(body, RDFXML) if data.nil?
      return if data.nil?

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
