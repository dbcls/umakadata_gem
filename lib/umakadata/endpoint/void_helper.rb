module Umakadata
  class Endpoint
    # Helper methods to evaluate endpoint's VoID Vocabulary
    #
    # @see https://www.w3.org/TR/void/
    #
    # @since 1.0.0
    module VoIDHelper
      # @return [Array<String>]
      def publishers
        void.publishers
      end

      # @return [Array<String>]
      def licenses
        void.licenses
      end

      module VoIDMethods
        # @return [Array<String>]
        def publishers
          @publishers ||= Array(result
                                  &.filter_by_property(RDF::Vocab::DC.publisher)
                                  &.map(&:object)
                                  &.map(&:value)
                                  &.uniq)
        end

        # @return [Array<String>]
        def licenses
          @licenses ||= Array(result
                                &.filter_by_property(RDF::Vocab::DC.license)
                                &.map(&:object)
                                &.map(&:value)
                                &.uniq)
        end

        # @return [Integer]
        def triples
          @triples ||= result
                         &.filter_by_property(RDF::Vocab::VOID.triples)
                         &.map(&:object)
                         &.map(&:object)
                         &.sum
        end
      end

      # Execute query to obtain VoID
      #
      # @return [Umakadata::Activity]
      #
      # @see https://www.w3.org/TR/void/#discovery
      #
      # @todo Concern about "Discovery via links in the dataset's documents"
      #   It might be necessary to obtain metadata by SPARQL query.
      #   See https://www.w3.org/TR/void/#discovery-links
      def void
        cache(:void) do
          http.get('/.well-known/void', Accept: Umakadata::SPARQL::Client::GRAPH_ALL).tap do |act|
            act.type = Activity::Type::VOID
            act.comment = if act.result.is_a?(Array) && act.result.first.is_a?(RDF::Statement)
                            "Obtained VoID from #{act.response&.url || 'N/A'}"
                          else
                            "Failed to obtain VoID from #{act.response&.url || 'N/A'}"
                          end

            class << act
              include VoIDMethods
            end
          end
        end
      end
    end
  end
end
