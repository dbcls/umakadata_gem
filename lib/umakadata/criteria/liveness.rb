require 'umakadata/sparql_helper'

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
          method_log = Umakadata::Logging::Log.new
          logger.push method_log unless logger.nil?
          response = Umakadata::SparqlHelper.query(uri, sparql_query, logger: method_log, options: {method: method})
          unless response.nil?
            method_log.criterion = "#{method.to_s.capitalize}: 200 HTTP response"
            return true
          end
          method_log.criterion = "#{method.to_s.capitalize}: HTTP response errorr"
        end

        false
      end

    end

  end

end
