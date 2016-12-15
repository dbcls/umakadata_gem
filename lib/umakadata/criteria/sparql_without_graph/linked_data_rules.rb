require 'umakadata/http_helper'
require 'umakadata/sparql_helper'
require 'umakadata/logging/log'

module Umakadata
  module Criteria
    module SPARQLWithoutGraph
      module LinkedDataRules

        include Umakadata::HTTPHelper

        REGEXP = /<title>(.*)<\/title>/

        def prepare(uri)
          @client = SPARQL::Client.new(uri, {'read_timeout': 5 * 60}) if @uri == uri && @client == nil
          @uri = uri
        end

        def http_subject?(uri, logger: nil)
          sparql_query = <<-'SPARQL'
SELECT
  *
WHERE {
  { ?s ?p ?o } .
  filter (!regex(STR(?s), "^http://", "i") && !isBLANK(?s))
}
LIMIT 1
SPARQL

          [:post, :get].each do |method|
            log = Umakadata::Logging::Log.new
            logger.push log unless logger.nil?
            results = Umakadata::SparqlHelper.query(uri, sparql_query, logger: log, options: {method: method})
            if results.is_a?(RDF::Query::Solutions)
              if results.count == 0
                log.result = 'HTTP-URI subject is found'
                logger.result = 'HTTP URIs are used' unless logger.nil?
                return true
              else
                log.result = 'Non-HTTP-URI subjects are found'
              end
            else
              log.result = 'Sparql query result could not be read in RDF format'
            end
          end
          logger.result = 'HTTP URIs are not used' unless logger.nil?
          false
        end

        def uri_provides_info?(uri, logger: nil)
          uri = self.get_subject_randomly(uri, logger: logger)
          if uri == nil
            logger.result = 'The endpoint does not have information about URI' unless logger.nil?
            return false
          end

          begin
            response = http_get_recursive(URI(uri), {}, logger: logger)
          rescue => e
            logger.result = 'An error occurred in getting uri recursively' unless logger.nil?
            return false
          end

          if !response.is_a?(Net::HTTPSuccess)
            logger.result = 'HTTP response is not 2xx Success' unless logger.nil?
            return false
          end

          if response.body.empty?
            logger.result = "#{uri} does not return any data" unless logger.nil?
            return false
          end

          logger.result = "#{uri} provides useful information" unless logger.nil?
          true
        end

        def get_subject_randomly(uri, logger: nil)
          sparql_query = <<-'SPARQL'
SELECT
  ?s
WHERE {
  { ?s ?p ?o } .
  filter (isURI(?s) && !regex(STR(?s), "^http://localhost", "i") && !regex (STR(?s), "^http://www.openlinksw.com", "i"))
}
LIMIT 1
OFFSET 100
SPARQL

          [:post, :get].each do |method|
            log = Umakadata::Logging::Log.new
            logger.push log unless logger.nil?
            results = Umakadata::SparqlHelper.query(uri, sparql_query, logger: log, options: {method: method})
            if results != nil
              if results[0] != nil
                log.result = "#{results[0][:s]} subject is found"
                return results[0][:s]
              else
                log.result = 'URI is not found'
              end
            else
              log.result = 'Sparql query result could not be read in RDF format'
            end
          end
          nil
        end

        def contains_links?(uri, logger: nil)
          same_as_log = Umakadata::Logging::Log.new
          logger.push same_as_log unless logger.nil?
          same_as = self.contains_same_as?(uri, logger: same_as_log)
          if same_as
            logger.result = "#{uri} includes links to other URIs" unless logger.nil?
            return true
          end

          contains_see_also_log = Umakadata::Logging::Log.new
          logger.push contains_see_also_log unless logger.nil?
          see_also = self.contains_see_also?(uri, logger: contains_see_also_log)
          if see_also
            logger.result = "#{uri} includes links to other URIs" unless logger.nil?
            return true
          end
          logger.result = "#{uri} does not include links to other URIs" unless logger.nil?
          false
        end

        def contains_same_as?(uri, logger: nil)
          sparql_query = <<-'SPARQL'
PREFIX owl:<http://www.w3.org/2002/07/owl#>
SELECT
  *
WHERE {
  { ?s owl:sameAs ?o } .
}
LIMIT 1
SPARQL

          [:post, :get].each do |method|
            log = Umakadata::Logging::Log.new
            logger.push log unless logger.nil?
            results = Umakadata::SparqlHelper.query(uri, sparql_query, logger: log, options: {method: method})
            if results != nil && results.count > 0
              log.result = "#{results.count} owl:sameAs statements are found"
              logger.result = "#{uri} has statements which contain owl:sameAs" unless logger.nil?
              return true
            end
            log.result = 'The owl:sameAs statement is not found'
          end
          logger.result = "#{uri} The endpoint does not have statements which contain owl:sameAs" unless logger.nil?
          false
        end

        def contains_see_also?(uri, logger: nil)
          sparql_query = <<-'SPARQL'
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT
  *
WHERE {
  { ?s rdfs:seeAlso ?o } .
}
LIMIT 1
SPARQL

          [:post, :get].each do |method|
            log = Umakadata::Logging::Log.new
            logger.push log unless logger.nil?
            results = Umakadata::SparqlHelper.query(uri, sparql_query, logger: log, options: {method: method})
            if results != nil && results.count > 0
              log.result = "#{results.count} rdfs:seeAlso statements are found"
              logger.result = "#{uri} has statements which contain rdfs:seeAlso" unless logger.nil?
              return true
            end
            log.result = 'The rdfs:seeAlso statement is not found'
          end

          logger.result = "#{uri} The endpoint does not have statements which contain rdfs:seeAlso" unless logger.nil?
          false
        end

      end
    end
  end
end
