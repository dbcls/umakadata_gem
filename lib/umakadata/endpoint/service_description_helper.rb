module Umakadata
  class Endpoint
    # Helper methods to evaluate endpoint's service description
    #
    # @see https://www.w3.org/TR/sparql11-service-description/
    #
    # @since 1.0.0
    module ServiceDescriptionHelper
      SD = RDF::Vocabulary.new('http://www.w3.org/ns/sparql-service-description#')

      # @return [Array<String>]
      def supported_language
        service_description.first.supported_language
      end

      # Execute query to obtain service description
      #
      # @return [Array<Umakadata::Activity>]
      def service_description
        cache(:service_description) do
          sd = http.get(::URI.parse(url).request_uri, Accept: Umakadata::SPARQL::Client::GRAPH_ALL)

          class << sd
            # @return [Array<String>]
            def supported_language
              @supported_language ||= Array(result
                                              &.filter_by_property(SD.supported_language)
                                              &.map(&:object)
                                              &.map(&:value)
                                              &.uniq)
            end
          end

          [sd]
        end
      end
    end
  end
end
