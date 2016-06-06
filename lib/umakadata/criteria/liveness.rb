require 'umakadata/sparql_helper'
require 'umakadata/logging/log'

module Umakadata

  module Criteria

    module Liveness
      ##
      # A boolan value whether if the SPARQL endpoint is alive.
      #
      # @param  uri [URI]: the target endpoint
      # @param  args [Hash]:
      # @return [Boolean]
      def alive?(uri, time_out, logger: nil)
        sparql_query = 'SELECT * WHERE {?s ?p ?o} LIMIT 1'

        [:post, :get].each do |method|
          request_log = Umakadata::Logging::Log.new
          logger.push request_log unless logger.nil?
          response = Umakadata::SparqlHelper.query(uri, sparql_query, logger: request_log, options: {method: method})
          if response.is_a? Net::HTTPOK
            request_log.result = "#{method.to_s.capitalize}: 200 HTTP response"
            logger.result = "The endpoint is alive" unless logger.nil?
            return true
          end
          if response.is_a? Net::HTTPResponse
            request_log.result = "#{method.to_s.capitalize}: #{response.code} HTTP response"
          else
            request_log.result = "#{method.to_s.capitalize}: HTTP connection could not be established"
          end
        end
        logger.result = "The endpoint is down" unless logger.nil?
        false
      end

    end

  end

end
