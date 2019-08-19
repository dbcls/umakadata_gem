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
      def supported_languages
        service_description.supported_languages
      end

      # Execute query to obtain service description
      #
      # @return [Umakadata::Activity]
      def service_description
        cache(:service_description) do
          http.get(::URI.parse(url).request_uri, Accept: Umakadata::SPARQL::Client::GRAPH_ALL).tap do |sd|
            class << sd
              # @return [Array<String>]
              def supported_languages
                @supported_languages ||= Array(result
                                                &.filter_by_property(SD.supported_language)
                                                &.map(&:object)
                                                &.map(&:value)
                                                &.uniq)
              end
            end
          end
        end
      end
    end
  end
end
