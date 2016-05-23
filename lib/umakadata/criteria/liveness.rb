require 'umakadata/http_helper'
require 'umakadata/error_helper'

module Umakadata

  module Criteria

    module Liveness

      include Umakadata::HTTPHelper
      include Umakadata::ErrorHelper

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
