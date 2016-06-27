require 'umakadata/data_format'

module Umakadata

  class ServiceDescription

    include Umakadata::DataFormat

    SD = 'http://www.w3.org/ns/sparql-service-description'.freeze

    ##
    # return the type of service description
    #
    # @return [String]
    attr_reader :type

    ##
    # return service description
    #
    # @return [String]
    attr_reader :text

    ##
    # return response headers
    #
    # @return [String]
    attr_reader :response_header

    ##
    # return modified
    #
    # @return [String]
    attr_reader :modified

    ##
    # return supported language
    #
    # @return [String]
    attr_reader :supported_language

    def initialize(http_response)
      @type = UNKNOWN
      @text = nil
      @modified = nil
      @response_header = ''
      @supported_language = ''
      body = http_response.body
      data = triples(body, TURTLE)
      if (!data.nil?)
        @text = body
        @type = TURTLE
      else
        data = triples(body, RDFXML)
        if (!data.nil?)
          @text = body
          @type = RDFXML
        else
          return
        end
      end

      time = []
      data.each do |subject, predicate, object|
        if predicate == RDF::URI("http://purl.org/dc/terms/modified")
          time.push Time.parse(object.to_s) rescue time.push nil
        end
        if predicate == RDF::URI("#{SD}#supportedLanguage")
          @supported_language = object.to_s.sub(/#{SD}#/, '') unless object.nil?
        end
      end
      @modified = time.compact.max

      http_response.each_key do |key|
        @response_header << key << ": " << http_response[key] << "\n"
      end
    end

  end
end
