require 'umakadata/data_format'

module Umakadata

  class ServiceDescription

    include Umakadata::DataFormat

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

    def initialize(http_response)
      @type = UNKNOWN
      @text = nil
      @response_header = ''
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

      http_response.each_key do |key|
        @response_header << key << ": " << http_response[key] << "\n"
      end
    end

  end
end
