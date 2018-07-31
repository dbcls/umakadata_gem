require 'umakadata/http_helper'
require 'umakadata/logging/log'
require 'umakadata/criteria/filter_clause'

module Umakadata
  module Criteria
    module ContentNegotiation
      include Umakadata::HTTPHelper
      include Umakadata::Criteria::FilterClause

      def check_content_negotiation(uri, allow_prefix, deny_prefix, case_sensitive, content_type, logger: nil)
        filter = filter_clause(allow_prefix, deny_prefix, case_sensitive)
        query = <<-"SPARQL"
SELECT
  ?s
WHERE {
        GRAPH ?g {
           ?s ?p ?o
           FILTER( #{filter} )
        } .
      }
LIMIT 1
        SPARQL
        results = nil
        [:post, :get].each do |method|
          request_log = Umakadata::Logging::Log.new
          logger.push request_log unless logger.nil?
          results = Umakadata::SparqlHelper.query(uri, query, logger: request_log, options: { method: method })
          if results.nil?
            request_log.result = "failed to retrieve subject starts with #{allow_prefix}"
          else
            request_log.result = "Success to pick up a subject which starts with #{allow_prefix}"
            break
          end
        end
        return false if results.nil? or results.first.nil?

        uri = results.first[:s]

        http_log = Umakadata::Logging::Log.new
        logger.push http_log unless logger.nil?
        args     = { :headers => { 'Accept' => content_type } }
        request  = URI(uri)
        response = http_head_recursive(request, args, logger: http_log)
        if !response.is_a?(Net::HTTPSuccess)
          http_log.result = '#{uri} does not return 200 HTTP response'
          logger.result   = "#{uri} does not support #{content_type} in the content negotiation" unless logger.nil?
          return false
        else
          http_log.result = 'The endpoint returns 200 HTTP response.'
        end

        result        = response.content_type == content_type
        logger.result = "#{uri} #{result ? 'supports' : 'does not support'} #{content_type} in the content negotiation" unless logger.nil?

        return result
      end

      include Umakadata::DataFormat

      def check_endpoint(uri, content_type, logger: nil)
        query = <<-SPARQL
CONSTRUCT {?s ?p ?o}
WHERE { GRAPH ?g { ?s ?p ?o } . }
LIMIT 1
        SPARQL

        response = nil
        %i[post get].each do |method|
          sparql_log = Umakadata::Logging::SparqlLog.new(uri, query)
          logger.push sparql_log unless logger.nil?
          begin
            client   = Umakadata::SparqlClient.new(uri, { method: method })
            response = client.query(query, content_type: content_type)
          rescue => e
            sparql_log.error = e
          end
          if response.nil?
            sparql_log.result = "Failed to retrieve #{uri}"
          else
            sparql_log.result = "Success to retrieve #{uri}"
            break
          end
        end
        return false if response.nil?

        result = nil
        case content_type
        when TURTLE
          result = response.is_a?(RDF::Turtle::Reader)
        when RDFXML
          result = response.is_a?(RDF::RDFXML::Reader)
        when HTML
          result = response.content_type == content_type
        else
          result = false
        end

        logger.result = "#{uri} #{result ? 'supports' : 'does not support'} #{content_type} in the content negotiation" unless logger.nil?
        return result
      end
    end
  end
end
