require 'umakadata/http_helper'
require 'umakadata/sparql_helper'
require 'umakadata/logging/criteria_log'

module Umakadata
  module Criteria
    module LinkedDataRules

      include Umakadata::HTTPHelper

      REGEXP = /<title>(.*)<\/title>/

      def prepare(uri)
        @client = SPARQL::Client.new(uri, {'read_timeout': 5 * 60}) if @uri == uri && @client == nil
        @uri = uri
      end

      def uri_subject?(uri, logger: nil)
        sparql_query = <<-'SPARQL'
SELECT
  *
WHERE {
GRAPH ?g { ?s ?p ?o } .
  filter (!isURI(?s) && !isBLANK(?s) && ?g NOT IN (
    <http://www.openlinksw.com/schemas/virtrdf#>
  ))
}
LIMIT 1
SPARQL

        [:post, :get].each do |method|
          log = Umakadata::Logging::CriteriaLog.new
          logger.push log unless logger.nil?
          results = Umakadata::SparqlHelper.query(uri, sparql_query, logger: log, options: {method: method})
          if results != nil
            if results.count == 0
              log.result = 'Nothing is found'
              return true
            else
              log.result = 'The non-URI subjects is found'
              return false
            end
          else
            log.result = 'An error occured in searching'
          end
        end
        false
      end

      def http_subject?(uri, logger: nil)
        sparql_query = <<-'SPARQL'
SELECT
  *
WHERE {
  GRAPH ?g { ?s ?p ?o } .
  filter (!regex(?s, "http://", "i") && !isBLANK(?s) && ?g NOT IN (
    <http://www.openlinksw.com/schemas/virtrdf#>
  ))
}
LIMIT 1
SPARQL

        [:post, :get].each do |method|
          log = Umakadata::Logging::CriteriaLog.new
          logger.push log unless logger.nil?
          results = Umakadata::SparqlHelper.query(uri, sparql_query, logger: log, options: {method: method})
          if results != nil
            if results.count == 0
              log.result = 'Nothing is found'
              return true
            else
              log.result = 'The non-HTTP-URI subjects is found'
              return false
            end
          else
            log.result = 'An error occured in searching'
          end
        end
        false
      end

      def uri_provides_info?(uri, logger: nil)
        uri = self.get_subject_randomly(uri, logger: logger)
        if uri == nil
          return false
        end
        log = Umakadata::Logging::CriteriaLog.new
        logger.push log unless logger.nil?
        begin
          response = http_get_recursive(URI(uri), {logger: log}, 10)
        rescue => e
          log.result = "INVALID URI: #{uri}"
          return false
        end

        if !response.is_a?(Net::HTTPSuccess)
          log.result = 'URI does not return 200 HTTP response'
          return false
        end

        if !response.body.empty?
          log.result = "URI returns any data"
          return true
        end
        log.result = 'URI returns emtpy'
        false
      end

      def get_subject_randomly(uri, logger: nil)
        sparql_query = <<-'SPARQL'
SELECT
  ?s
WHERE {
  GRAPH ?g { ?s ?p ?o } .
  filter (isURI(?s) && ?g NOT IN (
    <http://www.openlinksw.com/schemas/virtrdf#>
  ))
}
LIMIT 1
OFFSET 100
SPARQL

        [:post, :get].each do |method|
          log = Umakadata::Logging::CriteriaLog.new
          logger.push log unless logger.nil?
          results = Umakadata::SparqlHelper.query(uri, sparql_query, logger: log, options: {method: method})
          if results != nil && results[0] != nil
            log.result = 'URI is found'
            return results[0][:s]
          end
          log.result = 'URI does not find'
        end
        nil
      end

      def contains_links?(uri)
        self.prepare(uri)

        self.contains_same_as?() || self.contains_see_also?()
      end

      def contains_same_as?
        sparql_query = <<-'SPARQL'
PREFIX owl:<http://www.w3.org/2002/07/owl#>
SELECT
  *
WHERE {
  GRAPH ?g { ?s owl:sameAs ?o } .
}
LIMIT 1
SPARQL
        results = query(sparql_query)
        return results != nil && results.count > 0
      end

      def contains_see_also?
        sparql_query = <<-'SPARQL'
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT
  *
WHERE {
  GRAPH ?g { ?s rdfs:seeAlso ?o } .
}
LIMIT 1
SPARQL
        results = query(sparql_query)
        return results != nil && results.count > 0
      end

      def query(sparql_query)
        begin
          results = @client.query(sparql_query)
          if results.nil?
            @client.response(sparql_query)
            set_error('Endpoint URI is different from actual URI in executing query')
            return nil
          end
        rescue SPARQL::Client::MalformedQuery => e
          set_error("Query: #{sparql_query}, Error: #{e.message}")
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
          set_error("Query: #{sparql_query}, Error: #{message}")
        rescue => e
          set_error("Query: #{sparql_query}, Error: #{e.to_s}")
          return nil
        end

        return results
      end

    end
  end
end
