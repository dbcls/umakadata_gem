module Umakadata
  class Endpoint
    # Helper methods to evaluate endpoint's supports for SPARQL syntax
    #
    # @since 1.0.0
    module SyntaxHelper
      # Check whether if the endpoint support graph keyword
      #
      # @return [true, false] true if the endpoint support graph keyword
      def graph_keyword_supported?
        @graph_keyword_supported ||= graph_keyword_support.first.response.status == 200
      end

      # Check whether if the endpoint support service keyword
      #
      # @return [true, false] true if the endpoint support service keyword
      def service_keyword_supported?
        @service_keyword_supported ||= service_keyword_support.first.response.status == 200
      end

      # Execute query to check graph keyword support
      #
      # @return [Array<Umakadata::Activity>]
      def graph_keyword_support
        @graph_keyword_support ||= [sparql
                                      .construct(%i[s p o])
                                      .where(%i[s p o])
                                      .graph(:g)
                                      .limit(1)
                                      .execute]
      end

      # Execute query to check service keyword support
      #
      # @return [Array<Umakadata::Activity>]
      def service_keyword_support
        @service_keyword_support ||= begin
          query = "CONSTRUCT { ?s ?p ?o . } WHERE { SERVICE <#{url}> { ?s ?p ?o . } } LIMIT 1"
          [sparql.query(query)]
        end
      end
    end
  end
end
