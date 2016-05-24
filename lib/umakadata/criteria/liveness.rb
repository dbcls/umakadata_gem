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
        response = Umakadata::SparqlHelper.query(uri, sparql_query, logger: logger)
        !response.nil?
      end

    end

  end

end
