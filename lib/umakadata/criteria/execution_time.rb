require 'umakadata/http_helper'
require 'umakadata/error_helper'
require 'umakadata/logging/sparql_log'
require 'rdf/turtle'
require 'umakadata/sparql_helper'

module Umakadata
  module Criteria
    module ExecutionTime

      include Umakadata::ErrorHelper
      include Umakadata::SparqlHelper

      BASE_QUERY = <<-'SPARQL'
ASK{}
SPARQL

      TARGET_QUERY = <<-'SPARQL'
SELECT DISTINCT
  ?g
WHERE {
  GRAPH ?g {
    ?s ?p ?o
  }
}
SPARQL

      def execution_time(uri, logger: nil)
        base_response_time = self.response_time(uri, BASE_QUERY, logger)
        target_response_time = self.response_time(uri, TARGET_QUERY, logger)
        if base_response_time.nil? || target_response_time.nil?
          return nil
        end
        execution_time = target_response_time - base_response_time
        if execution_time < 0.0
          set_error('The response time of listing graph query was faster than the response time of ASK{} query')
        end
        return execution_time
      end

      def response_time(uri, sparql_query, logger)
        start_time = Time.now

        begin
          response = query(uri, sparql_query, logger: logger)
        rescue SPARQL::Client::ClientError, SPARQL::Client::ServerError => e
          puts e
          return nil
        rescue => e
          puts e
          return nil
        end

        Time.now - start_time
      end

    end
  end
end
