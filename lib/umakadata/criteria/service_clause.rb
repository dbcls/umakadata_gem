require 'umakadata/sparql_helper'
require 'umakadata/logging/log'

module Umakadata
  module Criteria
    module ServiceClause
      ##
      # A boolean value whether if the SPARQL endpoint supports service clause.
      #
      # @param uri [URI]: the target endpoint
      # @param args [Hash]:
      # @return [Boolean]
      def check_service_clause(uri, logger: nil)
        sparql_query = <<-"SPARQL"
SELECT * 
WHERE {
  SERVICE <#{uri}> { <http://example.com> ?p ?o }
} 
LIMIT 1
        SPARQL

        [:post, :get].each do |method|
          request_log = Umakadata::Logging::Log.new
          logger.push request_log unless logger.nil?
          response = Umakadata::SparqlHelper.query(uri, sparql_query, logger: request_log, options: { method: method })
          unless response.nil?
            request_log.result = "200 HTTP response"
            logger.result      = "The endpoint supports service clause."
            return true
          end
          request_log.result = "An error occurred in checking service clause for the endpoint"
        end
        logger.result = "The endpoint does not support service clause" unless logger.nil?
        false
      end
    end
  end
end
