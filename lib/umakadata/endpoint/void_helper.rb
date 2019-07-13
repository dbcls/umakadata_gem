module Umakadata
  class Endpoint
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
      def void
        @void ||= http.get('/.well-known/void', Accept: Umakadata::SPARQL::Client::GRAPH_ALL)
      end
    end
  end
end
