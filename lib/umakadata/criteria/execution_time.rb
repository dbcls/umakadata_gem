require 'umakadata/sparql_helper'
require 'umakadata/logging/log'

module Umakadata
  module Criteria
    module ExecutionTime

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
        base_query_log = Umakadata::Logging::Log.new
        logger.push base_query_log unless logger.nil?
        base_response_time = self.response_time(uri, BASE_QUERY, base_query_log)
        base_query_log.result = "The response time of most simple query was " + (base_response_time.nil? ? "N/A" : "#{base_response_time} second")

        target_query_log = Umakadata::Logging::Log.new
        logger.push target_query_log unless logger.nil?
        target_response_time = self.response_time(uri, TARGET_QUERY, target_query_log)
        target_query_log.result = "The response time of query for listing graphs was " + (target_response_time.nil? ? "N/A" : "#{target_response_time} second")

        if base_response_time.nil? || target_response_time.nil?
          logger.result = "Execution time was N/A" unless logger.nil?
          return nil
        end
        execution_time = target_response_time - base_response_time
        if execution_time < 0.0
          logger.result = 'The response time of query for listing graphs was faster than the response time of most simple query' unless logger.nil?
        else
          logger.result = "Execution time was #{execution_time} second" unless logger.nil?
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
