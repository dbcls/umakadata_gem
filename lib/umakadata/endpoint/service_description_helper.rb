module Umakadata
  class Endpoint
    # Helper methods to evaluate endpoint's service description
    #
    # @since 1.0.0
    module ServiceDescriptionHelper
      SD = RDF::Vocabulary.new('http://www.w3.org/ns/sparql-service-description#')

      # @return [Array<String>]
      def supported_language
        @supported_language ||= Array(sd.result
                                        &.select { |x| RDF::Statement.new(nil, SD.supported_language, nil).match? x }
                                        &.map { |x| x.object.value }
                                        &.uniq)
      end

      # Execute query to obtain service description
      #
      # @return [Umakadata::Query]
      def sd
        @sd ||= http.get(::URI.parse(url).request_uri, Accept: Umakadata::SPARQL::Client::GRAPH_ALL)
      end
    end
  end
end
