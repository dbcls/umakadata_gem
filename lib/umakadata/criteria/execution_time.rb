require 'umakadata/http_helper'
require 'umakadata/error_helper'
require 'umakadata/logging/sparql_log'
require 'sparql/client'
require 'rdf/turtle'

module Umakadata
  module Criteria
    module ExecutionTime

      REGEXP = /<title>(.*)<\/title>/

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

      def prepare(uri)
        @client = SPARQL::Client.new(uri, {'read_timeout': 5 * 60}) if @uri == uri && @client == nil
        @uri = uri
      end

      def set_client(client)
        @client = client
      end

      def execution_time(uri, logger: nil)
        self.prepare(uri)

        base_response_time = self.response_time(BASE_QUERY, logger)
        target_response_time = self.response_time(TARGET_QUERY, logger)
        if base_response_time.nil? || target_response_time.nil?
          return nil
        end
        execution_time = target_response_time - base_response_time
        if execution_time < 0.0
          set_error('The response time of listing graph query was faster than the response time of ASK{} query')
        end
        return execution_time
      end

      def response_time(sparql_query, logger)
        sparql_log = Umakadata::Logging::SparqlLog.new(@uri.to_s, sparql_query)
        logger.push sparql_log unless logger.nil?

        start_time = Time.now
        begin
          result = @client.query(sparql_query)
          if result.nil?
            sparql_log.error = 'Empty triples'
            return nil
          end
          sparql_log.response = @client.response(sparql_query)
        rescue SPARQL::Client::ClientError, SPARQL::Client::ServerError => e
          sparql_log.error = e
          return nil
        rescue => e
          sparql_log.error = e
          return nil
        end

        Time.now - start_time
      end

    end
  end
end
