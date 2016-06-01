require 'umakadata/http_helper'
require 'umakadata/sparql_helper'
require 'umakadata/logging/log'

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
          log = Umakadata::Logging::Log.new
          logger.push log unless logger.nil?
          results = Umakadata::SparqlHelper.query(uri, sparql_query, logger: log, options: {method: method})
          if results != nil
            if results.count == 0
              log.result = "#{method.to_s.capitalize}: Nothing was found"
              logger.result = "URIs are used as names" unless logger.nil?
              return true
            else
              log.result = "#{method.to_s.capitalize}: The non-URI subjects was found"
              logger.result = "URIs are not used as names" unless logger.nil?
              return false
            end
          else
            log.result = 'An error occured in searching'
          end
        end
        logger.result = "An error occured in searching" unless logger.nil?

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
          log = Umakadata::Logging::Log.new
          logger.push log unless logger.nil?
          results = Umakadata::SparqlHelper.query(uri, sparql_query, logger: log, options: {method: method})
          if results != nil
            if results.count == 0
              log.result = "#{method.to_s.capitalize}: Nothing is found"
              logger.result = "HTTP URIs are used" unless logger.nil?
              return true
            else
              log.result = "#{method.to_s.capitalize}: The non-HTTP-URI subjects is found"
              logger.result = "HTTP URIs are not used" unless logger.nil?
              return false
            end
          else
            log.result = 'An error occured in searching'
          end
        end
        logger.result = "An error occured in searching" unless logger.nil?

        false
      end

      def uri_provides_info?(uri, logger: nil)
        uri = self.get_subject_randomly(uri, logger: logger)
        if uri == nil
          return false
        end
        log = Umakadata::Logging::Log.new
        logger.push log unless logger.nil?
        begin
          response = http_get_recursive(URI(uri), {logger: log}, 10)
        rescue => e
          log.result = "INVALID URI: #{uri}"
          return false
        end

        if !response.is_a?(Net::HTTPSuccess)
          log.result = 'URI could not return 200 HTTP response'
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
          log = Umakadata::Logging::Log.new
          logger.push log unless logger.nil?
          results = Umakadata::SparqlHelper.query(uri, sparql_query, logger: log, options: {method: method})
          if results != nil && results[0] != nil
            log.result = 'URI is found'
            return results[0][:s]
          end
          log.result = 'URI could not find'
        end
        nil
      end

      def contains_links?(uri, logger: nil)
        self.contains_same_as?(uri, logger: logger) || self.contains_see_also?(uri, logger: logger)
      end

      def contains_same_as?(uri, logger: nil)
        sparql_query = <<-'SPARQL'
PREFIX owl:<http://www.w3.org/2002/07/owl#>
SELECT
  *
WHERE {
  GRAPH ?g { ?s owl:sameAs ?o } .
}
LIMIT 1
SPARQL

        [:post, :get].each do |method|
          log = Umakadata::Logging::Log.new
          logger.push log unless logger.nil?
          results = Umakadata::SparqlHelper.query(uri, sparql_query, logger: log, options: {method: method})
          if results != nil && results.count > 0
            log.result = 'The owl:sameAs statement is found'
            return true
          end
          log.result = 'The owl:sameAs statement could not find'
        end
        false
      end

      def contains_see_also?(uri, logger: nil)
        sparql_query = <<-'SPARQL'
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT
  *
WHERE {
  GRAPH ?g { ?s rdfs:seeAlso ?o } .
}
LIMIT 1
SPARQL

        [:post, :get].each do |method|
          log = Umakadata::Logging::Log.new
          logger.push log unless logger.nil?
          results = Umakadata::SparqlHelper.query(uri, sparql_query, logger: log, options: {method: method})
          if results != nil && results.count > 0
            log.result = 'The rdfs:seeAlso statement is found'
            return true
          end
          log.result = 'The rdfs:seeAlso statement could not find'
        end
        false
      end

    end
  end
end
