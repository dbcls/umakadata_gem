require 'umakadata/http_helper'
require 'umakadata/error_helper'
require 'umakadata/sparql_helper'

module Umakadata
  module Criteria
    module ExecutionTime

      include Umakadata::ErrorHelper

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
        response = Umakadata::SparqlHelper.query(uri, sparql_query, logger: logger)
        return nil if response.nil?
        Time.now - start_time
      end

    end
  end
end
