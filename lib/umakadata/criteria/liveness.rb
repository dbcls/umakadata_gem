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
      # @param  time_out [Integer]: the period in seconds to wait for a connection
      # @return [Boolean]
      def alive?(uri, time_out)
        query = 'SELECT * WHERE {?s ?p ?o} LIMIT 1'

        response = nil
        begin
          get_uri = URI(URI.encode(uri.to_s + '?query=' + query))
          response = Net::HTTP.get_response(get_uri)
        rescue => e
          response = e.message
        end
        return true if response.is_a?(Net::HTTPSuccess)

        begin
          response = Net::HTTP.post_form(URI(uri), {'query'=> query})
        rescue => e
          response = e.message
        end
        return true if response.is_a?(Net::HTTPSuccess)

        if response.is_a? Net::HTTPResponse
          set_error(response.code + "\s" + response.message)
        else
          set_error(response)
        end
        return false
      end

    end
  end
end
