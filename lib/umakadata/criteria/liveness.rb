require "umakadata/http_helper"
require "umakadata/error_helper"

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
        response = http_get(uri, nil, time_out)
        if !response.is_a? Net::HTTPOK
          if response.is_a? Net::HTTPResponse
            set_error(response.code + "\s" + response.message)
          else
            set_error(response)
          end
          return false
        end
        return true
      end
    end
  end
end
