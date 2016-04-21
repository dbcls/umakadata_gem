require 'umakadata/http_helper'
require 'umakadata/error_helper'

module Umakadata
  module Criteria
    module ContentNegotiation

      include Umakadata::HTTPHelper
      include Umakadata::ErrorHelper

      def check_content_negotiation(uri, content_type)
        query = <<-'SPARQL'
SELECT
  *
WHERE {
        GRAPH ?g { ?s ?p ?o } .
      }
LIMIT 1
SPARQL

        headers = {}
        headers['Accept'] = content_type
        request =  URI(uri.to_s + "?query=" + query)

        response = http_get_recursive(request, headers)
        if !response.is_a?(Net::HTTPSuccess)
          if response.is_a? Net::HTTPResponse
            set_error(response.code + "\s" + response.message)
          else
            set_error(response)
          end
          return false
        end

        return response.content_type == content_type

      end
    end
  end
end
