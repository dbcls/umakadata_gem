module Umakadata
  class Endpoint
    # Helper methods to evaluate endpoint's VoID Vocabulary
    #
    # @see https://www.w3.org/TR/void/
    #
    # @since 1.0.0
    module VoIDHelper
      # @return [Array<String>]
      def publisher
        void.publisher
      end

      # @return [Array<String>]
      def license
        void.license
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
      end

      # Execute query to obtain VoID
      #
      # @return [Array<Umakadata::Activity>]
      #
      # @see https://www.w3.org/TR/void/#discovery
      #
      # @todo Concern about "Discovery via links in the dataset's documents"
      #   It might be necessary to obtain metadata by SPARQL query.
      #   See https://www.w3.org/TR/void/#discovery-links
      def void
        cache(:void) do
          http.get('/.well-known/void', Accept: Umakadata::SPARQL::Client::GRAPH_ALL).tap do |void|
            class << void
              include VoIDMethods
            end
          end
        end
      end
    end
  end
end
