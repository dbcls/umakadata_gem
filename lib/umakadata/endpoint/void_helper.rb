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
        @publisher ||= Array(void.result
                               &.select { |x| RDF::Statement.new(nil, RDF::Vocab::DC.publisher, nil).match? x }
                               &.map { |x| x.object.value }
                               &.uniq)
      end

      # @return [Array<String>]
      def license
        @license ||= Array(void.result
                             &.select { |x| RDF::Statement.new(nil, RDF::Vocab::DC.license, nil).match? x }
                             &.map { |x| x.object.value }
                             &.uniq)
      end

      # Execute query to obtain VoID
      #
      # @return [Umakadata::Query]
      #
      # @see https://www.w3.org/TR/void/#discovery
      #
      # @todo Concern about "Discovery via links in the dataset's documents"
      #   It might be necessary to obtain metadata by SPARQL query.
      #   See https://www.w3.org/TR/void/#discovery-links
      def void
        @void ||= http.get('/.well-known/void', Accept: Umakadata::SPARQL::Client::GRAPH_ALL)
      end
    end
  end
end
