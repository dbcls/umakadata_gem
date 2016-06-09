require 'umakadata/http_helper'
require 'umakadata/logging/log'

module Umakadata
  module Criteria
    module ContentNegotiation

      include Umakadata::HTTPHelper

      def check_content_negotiation(uri, content_type, logger: nil)
        query = <<-'SPARQL'
SELECT
  *
WHERE {
        GRAPH ?g { ?s ?p ?o } .
      }
LIMIT 1
SPARQL

        args = {:headers => {'Accept' => content_type}}
        request = URI(uri.to_s + "?query=" + query)

        response = http_get_recursive(request, args, logger: logger)
        if !response.is_a?(Net::HTTPSuccess)
          logger.result = 'The endpoint does not return 200 HTTP response' unless logger.nil?
          return false
        end

        result = response.content_type == content_type
        if result
          logger.result = "The endpoint supports #{content_type} in the content negotiation" unless logger.nil?
        else
          logger.result = "The endpoint does not support #{content_type} in the content negotiation" unless logger.nil?
        end
        result
      end
    end
  end
end
