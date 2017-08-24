require 'umakadata/http_helper'
require 'umakadata/logging/log'

module Umakadata
  module Criteria
    module ContentNegotiation

      include Umakadata::HTTPHelper

      def check_content_negotiation(uri, prefix, content_type, logger: nil)
        query = <<-"SPARQL"
SELECT
  ?s
WHERE {
        GRAPH ?g {
           ?s ?p ?o
           FILTER regex(?s, "^#{prefix}")
        } .
      }
LIMIT 1
SPARQL
        results = nil
        [:post, :get].each do |method|
          request_log = Umakadata::Logging::Log.new
          logger.push request_log unless logger.nil?
          results = Umakadata::SparqlHelper.query(uri, query, logger: request_log, options: {method: method})
          if results.nil?
            request_log.result = "failed to retrieve subject starts with #{prefix}"
          else
            request_log.result = "Success to pick up a subject which starts with #{prefix}"
            break
          end
        end
        return false if results.nil? or results.first.nil?

        uri = results.first[:s]

        http_log = Umakadata::Logging::Log.new
        logger.push http_log unless logger.nil?
        args = {:headers => {'Accept' => content_type}}
        request = URI(uri)
        response = http_head_recursive(request, args, logger: http_log)
        if !response.is_a?(Net::HTTPSuccess)
          http_log.result = '#{uri} does not return 200 HTTP response'
          logger.result = "#{uri} does not support #{content_type} in the content negotiation" unless logger.nil?
          return false
        else
          http_log.result = 'The endpoint returns 200 HTTP response.'
        end

        result = response.content_type == content_type
        logger.result = "#{uri} #{result ? 'supports' : 'does not support'} #{content_type} in the content negotiation" unless logger.nil?

        return result
      end
    end
  end
end
