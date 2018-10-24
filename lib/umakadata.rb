require 'umakadata/version'

module Umakadata
  require 'json/ld'

  require 'rdf'
  require 'rdf/n3'
  require 'rdf/nquads'
  require 'rdf/ntriples'
  require 'rdf/rdfa'
  require 'rdf/rdfxml'
  require 'rdf/turtle'
  require 'rdf/json'
  require 'rdf/vocab'
  require 'rdf/xsd'

  require 'sparql'
  require 'sparql/client'

  require 'umakadata/criteria'
  require 'umakadata/sparql_grammar'
  require 'umakadata/linkset'
  require 'umakadata/graph_handler'
  require 'umakadata/no_graph_handler'
  require 'umakadata/linked_open_vocabularies'
  require 'umakadata/retriever'
end
