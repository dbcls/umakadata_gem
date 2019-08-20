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
        cors_support.response.headers['Access-Control-Allow-Origin'] == '*'
      end

      # Execute query to check CORS support
      #
      # @return [Umakadata::Activity]
      def cors_support
        cache(:cors_support) do
          sparql.ask(%i[s p o]).execute.tap do |act|
            act.type = Activity::Type::CORS_SUPPORT
            act.comment = if act.response&.headers&.dig('Access-Control-Allow-Origin') == '*'
                            "The response header includes 'Access-Control-Allow-Origin = *'."
                          else
                            "The response header does not include 'Access-Control-Allow-Origin = *'."
                          end
          end
        end
      end
    end
  end
end
