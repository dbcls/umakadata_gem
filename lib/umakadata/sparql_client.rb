require 'sparql/client'

module Umakadata
  class SparqlClient < SPARQL::Client

    attr_reader :http_request
    attr_reader :http_response

    def pre_http_hook(request)
      @http_request = request
    end

    def post_http_hook(response)
      @http_response = response
    end

  end
end
