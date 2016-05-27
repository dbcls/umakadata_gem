require 'umakadata/sparql_helper'
require 'umakadata/logging/criteria_log'

module Umakadata
  module Criteria
    class BasicSPARQL

      def initialize(uri)
        @uri = uri
      end

      def count_statements(logger: nil)
        sparql_query = 'SELECT COUNT(*) AS ?c WHERE { ?s ?p ?o }'

        [:post, :get].each do |method|
          log = Umakadata::Logging::CriteriaLog.new
          logger.push log unless logger.nil?
          result = Umakadata::SparqlHelper.query(@uri, sparql_query, logger: log, options: {method: method})
          unless result.nil?
            log.result = "Statements count: #{result[0][:c]}"
            return result[0][:c]
          end
          log.result = "Statements could not find"
        end
        nil
      end

      def nth_statement(offset)
        sparql_query = "SELECT * WHERE {?s ?p ?o} OFFSET #{offset} LIMIT 1"
        [:post, :get].each do |method|
          result = Umakadata::SparqlHelper.query(@uri, sparql_query, logger: nil, options: {method: method})
          return [ result[0][:s], result[0][:p], result[0][:o] ] unless result.nil? || result[0].nil?
        end
        nil
      end

    end
  end
end
