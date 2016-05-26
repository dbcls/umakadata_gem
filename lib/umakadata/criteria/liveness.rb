require 'umakadata/sparql_helper'
require 'umakadata/logging/criteria_log'

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
          request_log = Umakadata::Logging::CriteriaLog.new
          logger.push request_log unless logger.nil?
          response = Umakadata::SparqlHelper.query(uri, sparql_query, logger: request_log, options: {method: method})
          unless response.nil?
            request_log.result = "#{method.to_s.capitalize}: 200 HTTP response"
            return true
          end
          request_log.result = "#{method.to_s.capitalize}: HTTP response errorr"
        end

        false
      end

    end

  end

end
