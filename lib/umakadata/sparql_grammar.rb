module Umakadata

  module SparqlGrammar

    def support_graph_clause?(uri)
      sparql_query = 'SELECT * WHERE {GRAPH ?g {?s ?p ?o}} LIMIT 1'

      [:post, :get].each do |method|
        response = Umakadata::SparqlHelper.query(uri, sparql_query)
        unless response.nil?
          return true
        end
      end
      false
    end

  end

end
