require 'sparql/client'
require 'umakadata/http_header'

module Umakadata
  class SparqlClient < SPARQL::Client

    RESULTS = [RESULT_JSON, RESULT_XML, RESULT_BOOL, RESULT_TSV, RESULT_CSV].freeze

    attr_reader :http_request
    attr_reader :http_response

    def pre_http_hook(request)
      request['User-Agent'] = Umakadata::HTTPHeader::USER_AGENT
      @http_request = request
    end

    def post_http_hook(response)
      @http_response = response
    end

    def parse_rdf_serialization(response, options = {})
      RESULTS.each do |result|
        begin
          solutions = parse_response(response, {:content_type => result})
          return solutions
        rescue
        end
      end
      raise RDF::ReaderError, "no suitable rdf reader was found."
    end

  end
end
