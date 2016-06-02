require 'umakadata/sparql_helper'
require 'umakadata/logging/log'

module Umakadata
  module Criteria
    class BasicSPARQL

      def initialize(uri)
        @uri = uri
      end

      def count_statements(logger: nil)
        sparql_query = 'SELECT COUNT(*) AS ?c WHERE { ?s ?p ?o }'
        [:post, :get].each do |method|
          log = Umakadata::Logging::Log.new
          logger.push log unless logger.nil?
          result = Umakadata::SparqlHelper.query(@uri, sparql_query, logger: log, options: {method: method})
          unless result.nil?
            count = result[0][:c]
            log.result = "#{method.to_s.capitalize}: Statements count was #{count}"
            logger.result = "Statements count was #{count}" unless logger.nil?
            return count
          end
          log.result = "#{method.to_s.capitalize}: Statements was not found"
        end
        logger.result = "Statements count was N/A" unless logger.nil?
        nil
      end

      def nth_statement(offset, logger: nil)
        sparql_query = "SELECT * WHERE {?s ?p ?o} OFFSET #{offset} LIMIT 1"
        [:post, :get].each do |method|
          log = Umakadata::Logging::Log.new
          logger.push log unless log.nil?
          result = Umakadata::SparqlHelper.query(@uri, sparql_query, logger: log, options: {method: method})
          unless result.nil? || result[0].nil?
            log.result = "#{method.to_s.capitalize}: S is #{result[0][:s]}, P is #{result[0][:p]}, O is #{result[0][:o]}"
            return [ result[0][:s], result[0][:p], result[0][:o] ]
          end
          log.result = "#{method.to_s.capitalize}: Statements was not found"
        end
        nil
      end

    end
  end
end
