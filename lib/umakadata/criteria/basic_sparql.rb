require 'sparql/client'
require 'umakadata/error_helper'

module Umakadata
  module Criteria
    class BasicSPARQL

      REGEXP = /<title>(.*)<\/title>/

      include Umakadata::ErrorHelper

      def initialize(uri)
        @client = SPARQL::Client.new(uri)
      end

      def count_statements
        result = query("SELECT COUNT(*) AS ?c WHERE {?s ?p ?o}")
        return nil if result.nil?
        return result[0][:c]
      end

      def nth_statement(offset)
        result = query("SELECT * WHERE {?s ?p ?o} OFFSET #{offset} LIMIT 1")
        return nil if result.nil? || result[0].nil?
        return [ result[0][:s], result[0][:p], result[0][:o] ]
      end

      def query(query)
        begin
          results = @client.query(query)
          if results.nil?
            @client.response(query)
            set_error('Endpoint URI is different from actual URI in executing query')
            return nil
          end
        rescue SPARQL::Client::MalformedQuery => e
          set_error("Query: #{query}, Error: #{e.message}")
          return nil
        rescue SPARQL::Client::ClientError, SPARQL::Client::ServerError => e
          message = e.message.scan(REGEXP)[0]
          if message.nil?
            result = e.message.scan(/"datatype":\s"(.*\n)/)[0]
            if result.nil?
              message = ''
            else
              message = result[0].chomp
            end
          end
          set_error("Query: #{query}, Error: #{message}")
        rescue => e
          set_error("Query: #{query}, Error: #{e.to_s}")
          return nil
        end

        return results
      end

    end
  end
end
