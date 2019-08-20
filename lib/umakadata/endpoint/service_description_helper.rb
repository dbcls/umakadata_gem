module Umakadata
  class Endpoint
    # Helper methods to evaluate endpoint's Service Description
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

      # Execute query to obtain Service Description
      #
      # @return [Umakadata::Activity]
      def service_description
        cache(:service_description) do
          http.get(::URI.parse(url).request_uri, Accept: Umakadata::SPARQL::Client::GRAPH_ALL).tap do |act|
            act.type = Activity::Type::SERVICE_DESCRIPTION
            act.comment = if act.result.is_a?(Array) && act.result.first.is_a?(RDF::Statement)
                            "Obtained Service Description from #{act.response&.url || 'N/A'}"
                          else
                            "Failed to obtain Service Description from #{act.response&.url || 'N/A'}"
                          end

            class << act
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
