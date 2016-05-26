require 'umakadata/sparql_helper'
require 'umakadata/logging/criteria_log'

module Umakadata
  module Criteria
    module ExecutionTime

      include Umakadata::ErrorHelper

      BASE_QUERY = <<-'SPARQL'
ASK {}
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

        base_query_log = Umakadata::Logging::CriteriaLog.new
        logger.push base_query_log unless logger.nil?
        base_response_time = self.response_time(uri, BASE_QUERY, base_query_log)
        base_query_log.result = "Most Simple Query: #{base_response_time}"

        target_query_log = Umakadata::Logging::CriteriaLog.new
        logger.push target_query_log unless logger.nil?
        target_response_time = self.response_time(uri, TARGET_QUERY, target_query_log)
        target_query_log.result = "Query for Listing Graphs: #{target_response_time}"

        if base_response_time.nil? || target_response_time.nil?
          return nil
        end
        target_response_time - base_response_time
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
