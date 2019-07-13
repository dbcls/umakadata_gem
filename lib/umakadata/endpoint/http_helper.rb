module Umakadata
  class Endpoint
    # Helper methods to evaluate endpoint's supports for HTTP communication
    #
    # @since 1.0.0
    module HTTPHelper
      # Check whether if the endpoint returns CORS header
      #
      # @return [true, false] true if the endpoint returns CORS header
      #
      # @see https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
      def cors_supported?
        @cors_supported ||= cors_support.response.headers['Access-Control-Allow-Origin'] == '*'
      end

      # Execute query to check CORS support
      #
      # @return [Umakadata::Query]
      def cors_support
        @cors_support ||= sparql.ask(%i[s p o]).execute
      end
    end
  end
end
