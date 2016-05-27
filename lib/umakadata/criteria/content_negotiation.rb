require 'umakadata/http_helper'
require 'umakadata/logging/criteria_log'

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

        log = Umakadata::Logging::CriteriaLog.new
        logger.push log unless log.nil? unless logger.nil?


        args = {:headers => {'Accept' => content_type}, :logger => log}
        request = URI(uri.to_s + "?query=" + query)

        response = http_get_recursive(request, args, logger: log)
        if !response.is_a?(Net::HTTPSuccess)
          log.result = 'The endpoint could not return 200 HTTP response'
          return false
        end

        result = response.content_type == content_type
        if result
          log.result = "The endpoint supports #{content_type} format by content_negotiation"
        else
          log.result = "The endpoint could not support #{content_type} format by content_negotiation"
        end
        result
      end
    end
  end
end
