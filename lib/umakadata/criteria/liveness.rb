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
      def alive?(uri, time_out, logger:)
        query = 'SELECT * WHERE {?s ?p ?o} LIMIT 1'

        args = {
          :headers => {
            # Note: Use single quoted 'Accept', symbol :accept is NOT applicable to net/http
            'Accept' => [Umakadata::DataFormat::TURTLE, Umakadata::DataFormat::RDFXML].join(','),
          },
          :time_out => time_out,
          :logger => logger
        }

        response = http_get(URI.encode(uri.to_s + '?query=' + query), args)
        return true if response.is_a?(Net::HTTPSuccess)

        response = http_post(uri.to_s, {:query => query}.merge(args), args)
        return true if response.is_a?(Net::HTTPSuccess)

        false
      end

    end

  end

end
